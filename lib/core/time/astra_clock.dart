/// Canonical clock abstraction for all temporal reasoning in ASTRA.
/// Inject [FixedAstraClock] in tests; use [SystemAstraClock] in production.
abstract class AstraClock {
  DateTime now();
}

class SystemAstraClock implements AstraClock {
  @override
  DateTime now() => DateTime.now();
}

/// Fixed clock for deterministic unit tests.
class FixedAstraClock implements AstraClock {
  FixedAstraClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void set(DateTime value) => _fixed = value;

  void advance(Duration duration) => _fixed = _fixed.add(duration);
}
