import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/message.dart';

final messageListProvider = FutureProvider<List<Message>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final messagesJson = prefs.getStringList('messages') ?? [];
  return messagesJson.map((json) => Message.fromJson(jsonDecode(json))).toList();
});

final messageNotifierProvider = StateNotifierProvider<MessageNotifier, List<Message>>((ref) {
  return MessageNotifier();
});

class MessageNotifier extends StateNotifier<List<Message>> {
  MessageNotifier() : super([]);

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList('messages') ?? [];
    state = messagesJson.map((json) => Message.fromJson(jsonDecode(json))).toList();
  }

  Future<void> addMessage(String text, {String source = 'whatsapp'}) async {
    final msg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      source: source,
      receivedAt: DateTime.now(),
    );
    state = [msg, ...state];
    await _saveMessages();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = state.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('messages', messagesJson);
  }
}
