import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../core/design/tokens.dart';

/// Where one verse sits in the chapter scroll (scroll offsets).
typedef VerseSpan = ({int index, double top, double bottom});

/// Reads the laid-out verses of the chapter scroll: the list after the centre
/// verse grows down from offset 0, the list before it grows up from 0.
class VerseLayout {
  VerseLayout({
    required GlobalKey beforeKey,
    required GlobalKey afterKey,
    required this.centerIndex,
  }) : beforeKeyRef = beforeKey,
       afterKeyRef = afterKey;

  /// The verse top a swipe chose. Kept until the next touch, so a snap
  /// can't be re-decided mid-flight (that skipped 2-3 verses).
  double? lockedTarget;

  /// Scroll offset where the current touch began.
  double? touchStart;

  /// A new touch: forget the last decision.
  void touchDown(double pixels) {
    lockedTarget = null;
    touchStart = pixels;
  }

  /// The two lists' keys; replaced when the scroll is re-anchored.
  GlobalKey beforeKeyRef;
  GlobalKey afterKeyRef;
  final int Function() centerIndex;

  /// The verses currently laid out (on screen and in the cache), top first.
  List<VerseSpan> spans() {
    final out = <VerseSpan>[];
    // Debug builds forbid reading another object's size while a layout is
    // running (the viewport asks for a ballistic when its content changes).
    // Snapping is for the end of a swipe, so just skip that one case.
    var inLayout = false;
    assert(() {
      inLayout = RenderObject.debugActiveLayout != null;
      return true;
    }());
    if (inLayout) return out;
    final center = centerIndex();
    void read(GlobalKey key, {required bool before}) {
      final ro = key.currentContext?.findRenderObject();
      if (ro is! RenderSliverMultiBoxAdaptor) return;
      var child = ro.firstChild;
      while (child != null) {
        final pd = child.parentData! as SliverMultiBoxAdaptorParentData;
        final offset = pd.layoutOffset ?? 0;
        if (!child.hasSize) {
          child = ro.childAfter(child);
          continue;
        }
        final h = child.size.height;
        final i = pd.index ?? 0;
        out.add(
          before
              ? (index: center - 1 - i, top: -(offset + h), bottom: -offset)
              : (index: center + i, top: offset, bottom: offset + h),
        );
        child = ro.childAfter(child);
      }
    }

    read(beforeKeyRef, before: true);
    read(afterKeyRef, before: false);
    out.sort((a, b) => a.top.compareTo(b.top));
    return out;
  }

  /// The verse under [offset], if laid out.
  VerseSpan? at(double offset) {
    for (final s in spans()) {
      if (offset >= s.top && offset < s.bottom) return s;
    }
    return null;
  }
}

/// Scroll physics for reading verse by verse (owner, 2026-11-20: the swipe
/// is the selling feature). One scroll for the whole chapter, so the finger
/// always moves the text directly; where a fling comes to rest is chosen
/// here:
///
/// - A verse at most one screen tall is a page: a swipe goes to the next or
///   previous verse, a short slow drag springs back.
/// - Inside a long verse, a fling scrolls freely but always stops at the
///   verse's end or start; it never skips into the next verse.
/// - At a verse's end, one more swipe moves to the next verse's top; at its
///   start, to the previous verse. A slow drag more than halfway in settles
///   there.
class VerseSnapPhysics extends ScrollPhysics {
  const VerseSnapPhysics({required this.layout, super.parent});

  final VerseLayout layout;

  @override
  VerseSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      VerseSnapPhysics(layout: layout, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final base = super.createBallisticSimulation(position, velocity);
    if (position.outOfRange) return base;
    final tolerance = toleranceFor(position);
    // A snap already decided for this swipe stays decided, even when the
    // list re-lays out mid-flight and asks again.
    final locked = layout.lockedTarget;
    if (locked != null) {
      if ((locked - position.pixels).abs() < tolerance.distance) {
        layout.lockedTarget = null; // arrived
        return null;
      }
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        locked,
        velocity,
        tolerance: tolerance,
      );
    }
    final p = position.pixels;
    final vp = position.viewportDimension;
    final spans = layout.spans();
    final i = spans.indexWhere((s) => p >= s.top - 0.5 && p < s.bottom - 0.5);
    if (i < 0) return base;
    final s = spans[i];
    final next = i + 1 < spans.length ? spans[i + 1] : null;
    final prev = i > 0 ? spans[i - 1] : null;
    // The last resting offset that still shows only this verse.
    final end = math.max(s.top, s.bottom - vp);
    const slop = ReaderMetrics.edgeSlop;
    // A deliberate swipe: quick enough and long enough. Small touches and
    // nudges spring back instead of turning.
    final moved = (p - (layout.touchStart ?? p)).abs();
    final fast =
        velocity.abs() >= ReaderMetrics.snapVelocity &&
        moved >= ReaderMetrics.swipeMinDistance;

    double? target;
    if (fast && velocity > 0) {
      if (p >= end - slop) {
        target = next?.top;
      } else {
        // Free fling inside a long verse, stopping at its end at most.
        final landing = _landing(base, p);
        target = landing <= end ? null : end;
        if (target == null) return base;
      }
    } else if (fast && velocity < 0) {
      if (p > end + slop) {
        // Between this verse and the next: back to this verse.
        target = end;
      } else if (p <= s.top + slop) {
        // At the top: back to the previous verse (its end, so reading up
        // through a long verse stays continuous; a short verse's top).
        target = prev == null ? null : math.max(prev.top, prev.bottom - vp);
      } else {
        final landing = _landing(base, p);
        target = landing >= s.top ? null : s.top;
        if (target == null) return base;
      }
    } else if (p > end + slop && next != null) {
      // Slow release between two verses: settle on the nearer one.
      target = (p - end) / vp > 0.5 ? next.top : end;
    } else {
      return base;
    }
    if (target == null) return base;
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - p).abs() < tolerance.distance) return null;
    layout.lockedTarget = target;
    return ScrollSpringSimulation(
      spring,
      p,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  /// Where an unconstrained fling would come to rest.
  static double _landing(Simulation? base, double p) =>
      base == null ? p : base.x(30);

  @override
  bool get allowImplicitScrolling => false;
}
