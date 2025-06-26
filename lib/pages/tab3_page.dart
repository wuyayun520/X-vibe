import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/chat_history_service.dart';
import '../models/user_model.dart';
import '../pages/chat_page.dart';

class Tab3Page extends StatefulWidget {
  const Tab3Page({super.key});

  @override
  State<Tab3Page> createState() => _Tab3PageState();
}

class _Tab3PageState extends State<Tab3Page> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 加载用户数据
      await _loadUserData();
      
      // 加载聊天历史（只显示真实的聊天记录）
      await _loadChatHistory();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final String response = await rootBundle.loadString('assets/petds.json');
      final data = json.decode(response);
      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(data['custpet']);
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await ChatHistoryService.getChatHistory();
      
      setState(() {
        _chatHistory = history;
      });
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  void _navigateToChat(Map<String, dynamic> userData) {
    // 转换数据格式以匹配UserModel
    final userModel = UserModel(
      userId: userData['userId'] ?? userData['name'] ?? 'unknown',
      name: userData['userName'] ?? userData['name'] ?? 'Unknown User',
      usericon: userData['userIcon'] ?? userData['userpic'] ?? 'assets/images/default_avatar.png',
      chatBg: userData['userpicBg'] ?? 'assets/images/xvibe_bg1.png',
      introduction: userData['introduction'] ?? 'No introduction available.',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(user: userModel),
      ),
    ).then((_) {
      // 返回时刷新聊天历史
      _loadChatHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/xvibe_bg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF24F8D5)),
                  ),
                )
              : Column(
                  children: [
                    // 顶部标题
                    _buildHeader(),
                    
                    // 顶部头像列表 - 显示所有用户
                    _buildTopAvatarList(),
                    
                    // 分隔线和All标签
                    _buildSectionDivider(),
                    
                    // 聊天历史列表 - 只显示真实的聊天记录
                    Expanded(
                      child: _buildChatHistoryList(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: const Row(
        children: [
          Text(
            'Chat',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAvatarList() {
    // 显示所有用户的头像
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allUsers.length,
        itemBuilder: (context, index) {
          final user = _allUsers[index];
          return GestureDetector(
            onTap: () => _navigateToChat({
              'userId': user['userId'],
              'userName': user['name'],
              'userIcon': user['userpic'],
              'userpicBg': user['userpicBg'],
              'introduction': user['introduction'],
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF24F8D5),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            user['userpic'] ?? 'assets/images/default_avatar.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // 在线状态指示器
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: const Text(
              'All',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF24F8D5),
              ),
            ),
          ),
          const SizedBox(width: 8),
        
        ],
      ),
    );
  }

  Widget _buildChatHistoryList() {
    if (_chatHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting with someone!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final chat = _chatHistory[index];
        return _buildChatHistoryItem(chat);
      },
    );
  }

  Widget _buildChatHistoryItem(Map<String, dynamic> chat) {
    return GestureDetector(
      onTap: () => _navigateToChat(chat),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 用户头像
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF24F8D5),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      chat['userIcon'] ?? 'assets/images/default_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 25,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 在线状态指示器
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // 聊天内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名和时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        ChatHistoryService.formatTimestamp(chat['timestamp'] ?? 0),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 最后一条消息
                  Text(
                    chat['lastMessage'] ?? 'No message',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // 未读消息数量（如果有的话）
            if (chat['unreadCount'] != null && chat['unreadCount'] > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${chat['unreadCount']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 