/// Plays notes one after another. Only native builds set one, and it only
/// makes sound inside AERA Recovery.
typedef NotePlayer = Future<void> Function(
  List<double> hz,
  int milliseconds,
  double volume,
);

NotePlayer? nativeSpeaker;
