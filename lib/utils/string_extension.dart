extension StringExtension on String {
  String toCapitalized() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String toTitleCase() {
    return split(' ').map((word) => word.toCapitalized()).join(' ');
  }
}
