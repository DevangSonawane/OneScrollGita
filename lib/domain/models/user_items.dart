/// A favourite, bookmark or history row. [at] is when it was saved or last
/// read.
class SavedItem {
  const SavedItem({required this.verseId, required this.at});

  final String verseId;
  final DateTime at;
}

class SavedState {
  const SavedState({required this.isFavourite, required this.isBookmarked});

  final bool isFavourite;
  final bool isBookmarked;
}
