/// The lifecycle of a letter as seen by the user.
///
/// `sealed` and `ready` are derived from the opening time. `opened` is only
/// derived from the persisted `openedAt`, never from the current time alone.
enum LetterStatus {
  draft,
  sealed,
  ready,
  opened;

  bool get isOpenable =>
      this == LetterStatus.ready || this == LetterStatus.opened;
}
