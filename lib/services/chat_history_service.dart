import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatHistoryService {
  static const String _chatHistoryKey = 'chat_history';

  // 聊天历史数据结构
  static Map<String, dynamic> _createChatHistory(String userId, String userName, String userIcon, String lastMessage, DateTime timestamp, {String? userpicBg}) {
    return {
      'userId': userId,
      'userName': userName,
      'userIcon': userIcon,
      'userpicBg': userpicBg ?? 'assets/images/xvibe_bg1.png',
      'lastMessage': lastMessage,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'unreadCount': 0,
    };
  }

  // 获取所有聊天历史
  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_chatHistoryKey);
    
    if (historyJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> historyList = json.decode(historyJson);
      return historyList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // 添加或更新聊天历史
  static Future<void> addOrUpdateChatHistory(String userId, String userName, String userIcon, String lastMessage, {String? userpicBg}) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getChatHistory();
    final timestamp = DateTime.now();
    
    // 查找是否已存在该用户的聊天记录
    final existingIndex = history.indexWhere((chat) => chat['userId'] == userId);
    
    if (existingIndex != -1) {
      // 更新现有记录，保留原有的userpicBg如果新的没有提供
      final existingBg = history[existingIndex]['userpicBg'];
      history[existingIndex] = _createChatHistory(userId, userName, userIcon, lastMessage, timestamp, userpicBg: userpicBg ?? existingBg);
    } else {
      // 添加新记录
      history.insert(0, _createChatHistory(userId, userName, userIcon, lastMessage, timestamp, userpicBg: userpicBg));
    }
    
    // 按时间戳排序，最新的在前面
    history.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    // 保存到本地存储
    await prefs.setString(_chatHistoryKey, json.encode(history));
  }

  // 删除聊天历史
  static Future<void> deleteChatHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getChatHistory();
    
    history.removeWhere((chat) => chat['userId'] == userId);
    
    await prefs.setString(_chatHistoryKey, json.encode(history));
  }

  // 清空所有聊天历史
  static Future<void> clearAllChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
  }

  // 获取最近聊天的用户（用于顶部头像显示）
  static Future<List<Map<String, dynamic>>> getRecentChatUsers({int limit = 10}) async {
    final history = await getChatHistory();
    return history.take(limit).toList();
  }

  // 格式化时间显示
  static String formatTimestamp(int timestamp) {
    final DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${messageTime.day}/${messageTime.month}';
    }
  }
} 