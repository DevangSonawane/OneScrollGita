/// Crisis helpline shown for sensitive searches (PRD_v2 section 11).
///
/// MUST BE VERIFIED BY THE OWNER BEFORE RELEASE (docs/review-needed.md).
/// Left empty on purpose: never invent a number. While empty, the call
/// line is hidden and only the care message shows.
abstract final class HelplineConfig {
  /// Digits only, for example as given by the verified service.
  static const number = '';

  /// Shown on the call line, for example the service's name.
  static const label = '';
}

const careMessage =
    'If you are in pain or thinking of harming yourself, please talk to '
    'someone you trust or contact a local crisis line right now. You do not '
    'have to carry this alone.';
