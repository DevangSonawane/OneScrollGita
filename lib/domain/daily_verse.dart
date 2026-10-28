/// Deterministic "verse of the day" (PRD section 2).
///
/// One entry per local calendar day, random-looking, and no repeats until
/// every entry has been shown once. No storage and no network.
library;

final _epoch = DateTime.utc(2024, 1, 1);

/// Whole days since 2024-01-01, computed on the local Y-M-D with UTC
/// arithmetic so daylight-saving changes never shift it.
int dayNumber(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day).difference(_epoch).inDays;

/// Index (0..n-1) of today's entry in the flattened list of all entries.
int dailyEntryIndex(DateTime local, int n) {
  if (n <= 0) throw ArgumentError.value(n, 'n', 'must be positive');
  final day = dayNumber(local);
  final cycle = _floorDiv(day, n);
  final position = day - cycle * n;
  return cyclePermutation(cycle, n)[position];
}

/// The order of entries for one full cycle.
List<int> cyclePermutation(int cycle, int n) {
  final perm = _shuffled(cycle, n);
  if (n > 1) {
    final previousLast = _shuffled(cycle - 1, n)[n - 1];
    if (perm[0] == previousLast) {
      final tmp = perm[0];
      perm[0] = perm[1];
      perm[1] = tmp;
    }
  }
  return perm;
}

List<int> _shuffled(int cycle, int n) {
  final rng = Mulberry32(cycle * 0x9E3779B1 + 0x5BD1E995);
  final list = List<int>.generate(n, (i) => i);
  for (var i = n - 1; i > 0; i--) {
    final j = rng.nextUint32() % (i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}

int _floorDiv(int a, int b) {
  final q = a ~/ b;
  return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q;
}

/// Small hand-written PRNG so results never change across Dart versions.
class Mulberry32 {
  Mulberry32(int seed) : _state = seed & _mask;

  static const _mask = 0xFFFFFFFF;
  int _state;

  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t ^= (t + _imul(t ^ (t >>> 7), t | 61)) & _mask;
    return (t ^ (t >>> 14)) & _mask;
  }

  static int _imul(int a, int b) => (a * b) & _mask;
}
