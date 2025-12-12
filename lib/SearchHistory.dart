class SearchHistory {
  // List of user's search history
  static final Map<String, List<String>> _historyByUser = {};

  // Gets the search for a specific user
  static List<String> getHistory(String userId) {
    return _historyByUser[userId] ?? [];
  }

  // Stores the search for a specific user
  static void addHistory(String userId, String value) {
    _historyByUser.putIfAbsent(userId, () => []);
    _historyByUser[userId]!.remove(value); // avoid duplicates
    _historyByUser[userId]!.insert(0, value);
  }

  // Deletes a search result for a specific user
  static void removeSearchResult(String userId, int index) {
    _historyByUser[userId]?.removeAt(index);
  }

  // Clears the entire search history for a specific user to be used on logout
  static void clearHistory(String userId) {
    _historyByUser[userId]?.clear();
  }
}
