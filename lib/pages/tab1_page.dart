import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'user_profile_page.dart';
import '../services/follow_service.dart';

class Tab1Page extends StatefulWidget {
  const Tab1Page({super.key});

  @override
  State<Tab1Page> createState() => _Tab1PageState();
}

class _Tab1PageState extends State<Tab1Page> {
  PageController _pageController = PageController();
  Timer? _timer;
  List<Map<String, dynamic>> _randomUsers = [];
  List<Map<String, dynamic>> _allUsers = []; // 存储所有用户数据
  List<Map<String, dynamic>> _popularUsers = []; // Popular用户列表
  List<Map<String, dynamic>> _followUsers = []; // Follow用户列表
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedOption = 0; // 0: Popular, 1: Follow

  @override
  void initState() {
    super.initState();
    _loadRandomUsers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadRandomUsers() async {
    try {
      // 加载JSON数据
      String jsonString = await DefaultAssetBundle.of(context).loadString('assets/petds.json');
      Map<String, dynamic> jsonData = json.decode(jsonString);
      List<dynamic> allUsers = jsonData['custpet'];
      
      // 存储所有用户数据
      _allUsers = List<Map<String, dynamic>>.from(allUsers);
      
      // 分配用户到不同列表
      _popularUsers = _allUsers.take(7).toList(); // 前7个用户为Popular
      _followUsers = _allUsers.skip(7).toList(); // 剩余用户为Follow
      
      // 随机选择4个用户用于轮播器（从所有用户中选择）
      List<Map<String, dynamic>> shuffledUsers = List<Map<String, dynamic>>.from(_allUsers);
      shuffledUsers.shuffle(Random());
      
      setState(() {
        _randomUsers = shuffledUsers.take(4).toList();
        _isLoading = false;
      });
      
      // 启动自动滚动
      _startAutoScroll();
      
      print('Loaded ${_randomUsers.length} users for carousel');
      print('Popular users: ${_popularUsers.length}');
      print('Follow users: ${_followUsers.length}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
      print('Error loading users: $e');
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_randomUsers.isNotEmpty && _pageController.hasClients) {
        _currentIndex = (_currentIndex + 1) % _randomUsers.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(user: user),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 内容图片 - 占据卡片上半部分
              Container(
                width: double.infinity,
                height: 200,
                child: user['userpic'] != null
                    ? Image.asset(
                        user['userpic'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Image load error: $error for ${user['userpic']}');
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              
              // 用户信息区域
              Container(
                height: 120,
                child: Stack(
                  children: [
                    // 用户名 - 位置不变
                    Positioned(
                      top: 24,  // 12 (原padding) + 12 (原SizedBox)
                      left: 12,
                      child: Text(
                        user['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // 用户背景介绍 - 按要求定位
                    Positioned(
                      top: 24 + 16 + 10,  // 用户名位置 + 用户名高度 + 10px间距
                      left: 10,  // 距离左边10px
                      right: 20 + 70 + 20,  // 距离右边关注按钮20px (按钮宽度70px + 右边距20px)
                      bottom: 10,  // 距离底部10px
                      child: Text(
                        user['introduction'] ?? 'No introduction',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Follow按钮 - 使用FutureBuilder显示动态状态
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: FutureBuilder<bool>(
                        future: FollowService.isFollowing(user['name'] ?? 'unknown_user'),
                        builder: (context, snapshot) {
                          bool isFollowing = snapshot.data ?? false;
                          return ElevatedButton(
                            onPressed: () async {
                              String userId = user['name'] ?? 'unknown_user';
                              try {
                                if (isFollowing) {
                                  await FollowService.unfollowUser(userId);
                                } else {
                                  await FollowService.followUser(userId);
                                }
                                // 刷新状态
                                setState(() {});
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('操作失败: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.grey[400] : const Color(0xFF24F8D5),
                              foregroundColor: isFollowing ? Colors.white : Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              minimumSize: const Size(70, 28),
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Popular 按钮
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedOption != 0) {
                  setState(() {
                    _selectedOption = 0;
                  });
                }
              },
              child: Image.asset(
                _selectedOption == 0 
                    ? 'assets/images/xvibe_home_popular_pre.png'
                    : 'assets/images/xvibe_home_popular_nor.png',
                height: 56,
                fit: BoxFit.fill,
              ),
            ),
          ),
          
          const SizedBox(width: 6),
          
          // Follow 按钮
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedOption != 1) {
                  setState(() {
                    _selectedOption = 1;
                  });
                }
              },
              child: Image.asset(
                _selectedOption == 1 
                    ? 'assets/images/xvibe_home_follow_pre.png'
                    : 'assets/images/xvibe_home_follow_nor.png',
                height: 56,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    List<Map<String, dynamic>> displayUsers = _selectedOption == 0 ? _popularUsers : _followUsers;
    
    if (displayUsers.isEmpty) {
      return const Center(
        child: Text(
          'No users available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 一排两个
          crossAxisSpacing: 12, // 卡片之间的水平间距
          mainAxisSpacing: 16, // 卡片之间的垂直间距
          childAspectRatio: 0.75, // 卡片宽高比，调整卡片高度
        ),
        itemCount: displayUsers.length,
        itemBuilder: (context, index) {
          final user = displayUsers[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(user: user),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 内容图片
                    Expanded(
                      flex: 3, // 图片占据大部分空间
                      child: Container(
                        width: double.infinity,
                        child: user['userpic'] != null
                            ? Image.asset(
                                user['userpic'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                    ),
                    
                    // 内容信息区域
                    Expanded(
                      flex: 2, // 信息区域占据较小空间
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 内容标题
                            Text(
                              user['introduction'] ?? 'No title available',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const Spacer(),
                            
                            // 用户信息和点赞
                            Row(
                              children: [
                                // 用户头像
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300],
                                  ),
                                  child: user['userpic'] != null
                                      ? ClipOval(
                                          child: Image.asset(
                                            user['userpic'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Colors.grey[600],
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                ),
                                
                                const SizedBox(width: 6),
                                
                                // 用户名
                                Expanded(
                                  child: Text(
                                    user['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                
                                // 点赞数和图标
                                Row(
                                  children: [
                                    Text(
                                      '${Random().nextInt(500) + 50}', // 随机生成点赞数
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.favorite,
                                      size: 12,
                                      color: Colors.red[400],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/xvibe_bg1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部文字图片
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 16),
                  child: Image.asset(
                    'assets/images/xvibe_home_top.png',
                    height: 27,
                    fit: BoxFit.fitHeight,
                    errorBuilder: (context, error, stackTrace) {
                      print('Top image load error: $error');
                      return Container(
                        height: 27,
                        color: Colors.red,
                        child: const Text('Image Error', style: TextStyle(color: Colors.white)),
                      );
                    },
                  ),
                ),
                
                // 用户卡片轮播器
                const SizedBox(height: 17),
                SizedBox(
                  height: 320,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF24F8D5),
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : _randomUsers.isNotEmpty
                              ? PageView.builder(
                                  controller: _pageController,
                                  itemCount: _randomUsers.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserCard(_randomUsers[index]);
                                  },
                                )
                              : const Center(
                                  child: Text(
                                    'No users available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                ),
                
                // 轮播器和切换按钮之间的间距
                const SizedBox(height: 20),
                
                // 切换按钮
                _buildToggleButtons(),
                
                // 切换按钮和用户列表之间的间距
                const SizedBox(height: 20),
                
                // 用户列表
                if (!_isLoading && _errorMessage == null)
                  _buildUserList(),
                
                // 底部间距
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 