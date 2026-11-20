import 'package:flutter/foundation.dart';

/// Owner test builds only (PRD_v6 section 8): building with
/// `--dart-define=OWNER_PREVIEW=true` turns on the debug-only previews
/// (Listen on the pretend engine, demo prices, the pretend switches) in a
/// release build for the owner's own phone. Store builds never pass it; a
/// banner on Profile makes such a build obvious.
const ownerPreview = bool.fromEnvironment('OWNER_PREVIEW');

/// Debug builds, or an owner preview build.
bool get previewBuild => kDebugMode || ownerPreview;
