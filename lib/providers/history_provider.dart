import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryItem {
  final String domain;
  final DateTime timestamp;
  final String? title;

  HistoryItem({
    required this.domain,
    required this.timestamp,
    this.title,
  });

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'timestamp': timestamp.toIso8601String(),
        'title': title,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        domain: json['domain'],
        timestamp: DateTime.parse(json['timestamp']),
        title: json['title'],
      );
}

class HistoryProvider extends ChangeNotifier {
  List<HistoryItem> _history = [];
  List<HistoryItem> get history => _history;

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('search_history') ?? [];
    _history = data.map((e) => HistoryItem.fromJson(jsonDecode(e))).toList();
    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> addToHistory(String domain, {String? title}) async {
    // Remove duplicate if exists
    _history.removeWhere((e) => e.domain == domain);
    _history.insert(
      0,
      HistoryItem(domain: domain, timestamp: DateTime.now(), title: title),
    );
    // Keep only last 50 entries
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }
    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeFromHistory(String domain) async {
    _history.removeWhere((e) => e.domain == domain);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('search_history', data);
  }
}
