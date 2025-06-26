import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'post_detail_page.dart';
import 'video_player_page.dart';
import '../services/comment_service.dart';
import 'dart:math';

class Tab2Page extends StatefulWidget {
  const Tab2Page({super.key});

  @override
  State<Tab2Page> createState() => _Tab2PageState();
}

class _Tab2PageState extends State<Tab2Page> {
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _filteredPosts = []; // 搜索过滤后的动态
  List<Map<String, dynamic>> _hotTopics = []; // 存储热门话题
  Map<String, int> _commentCounts = {}; // 存储每个动态的评论数量
  Map<String, int> _likeCounts = {}; // 存储每个动态的点赞数量
  Map<String, bool> _likedPosts = {}; // 存储用户点赞状态
  Set<String> _hiddenPosts = {}; // 存储被隐藏的动态ID
  bool _isLoading = true;
  bool _isSearching = false; // 是否正在搜索
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPosts() async {
    try {
      final String response = await rootBundle.loadString('assets/petds.json');
      final data = json.decode(response);
      final List<dynamic> users = data['custpet'];
      
      // 提取所有用户的动态
      List<Map<String, dynamic>> allPosts = [];
      for (var user in users) {
        if (user['post'] != null && user['post'].isNotEmpty) {
          for (var post in user['post']) {
            allPosts.add({
              'userId': user['userId'],
              'userName': user['name'],
              'userPic': user['userpic'],
              'userIcon': user['userIcon'],
              'introduction': user['introduction'],
              'sign': user['sign'],
              'postId': post['postId'],
              'postMsg': post['postmsg'],
              'playUrl': post['playUrl'],
              'timestamp': DateTime.now().subtract(Duration(hours: allPosts.length)).millisecondsSinceEpoch,
            });
          }
        }
      }
      
      // 按时间戳排序（最新的在前面）
      allPosts.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      
      // 随机选择3个动态作为热门话题
      List<Map<String, dynamic>> hotTopics = [];
      if (allPosts.isNotEmpty) {
        List<Map<String, dynamic>> shuffledPosts = List.from(allPosts);
        shuffledPosts.shuffle(Random());
        hotTopics = shuffledPosts.take(3).toList();
      }
      
      setState(() {
        _userPosts = allPosts;
        _hotTopics = hotTopics;
        _filteredPosts = allPosts; // 初始化过滤列表
      });
      
      // 加载每个动态的评论数量
      await _loadCommentCounts();
      
    } catch (e) {
      print('Error loading user posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCommentCounts() async {
    Map<String, int> counts = {};
    Map<String, int> likeCounts = {};
    Map<String, bool> likedPosts = {};
    
    for (var post in _userPosts) {
      final postId = post['postId'];
      final count = await CommentService.getCommentCount(postId);
      final likeCount = await CommentService.getLikeCount(postId);
      final isLiked = await CommentService.isLiked(postId);
      
      counts[postId] = count;
      likeCounts[postId] = likeCount;
      likedPosts[postId] = isLiked;
    }
    
    setState(() {
      _commentCounts = counts;
      _likeCounts = likeCounts;
      _likedPosts = likedPosts;
      _isLoading = false;
    });
  }

  // 切换点赞状态
  void _toggleLike(String postId) async {
    final isLiked = _likedPosts[postId] ?? false;
    final newLikedState = !isLiked;
    final currentCount = _likeCounts[postId] ?? 0;
    final newCount = newLikedState ? currentCount + 1 : currentCount - 1;
    
    // 更新本地状态
    setState(() {
      _likedPosts[postId] = newLikedState;
      _likeCounts[postId] = newCount;
    });
    
    // 保存到持久化存储
    await CommentService.setLiked(postId, newLikedState);
    await CommentService.updateLikeCount(postId, newCount);
    
    // 显示点赞反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newLikedState ? 'Liked!' : 'Like removed'),
        backgroundColor: newLikedState ? const Color(0xFF4CAF50) : const Color(0xFF666666),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatTimeAgo(int timestamp) {
    final DateTime postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(postTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // 从详情页返回时刷新数据
  Future<void> _refreshPostData(String postId) async {
    final commentCount = await CommentService.getCommentCount(postId);
    final likeCount = await CommentService.getLikeCount(postId);
    final isLiked = await CommentService.isLiked(postId);
    
    setState(() {
      _commentCounts[postId] = commentCount;
      _likeCounts[postId] = likeCount;
      _likedPosts[postId] = isLiked;
    });
  }

  // 显示举报动态对话框
  void _showReportPostDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Report Post',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this post?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              _buildReportOption('Inappropriate content', Icons.warning_outlined, post),
              _buildReportOption('Harassment or bullying', Icons.person_off_outlined, post),
              _buildReportOption('False information', Icons.info_outline, post),
              _buildReportOption('Spam', Icons.block_outlined, post),
              _buildReportOption('Other reasons', Icons.more_horiz_outlined, post),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建举报选项
  Widget _buildReportOption(String reason, IconData icon, Map<String, dynamic> post) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _submitPostReport(reason, post);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              reason,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 提交举报并隐藏动态
  void _submitPostReport(String reason, Map<String, dynamic> post) {
    final postId = post['postId'];
    
    setState(() {
      _hiddenPosts.add(postId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post reported for: $reason\nPost has been hidden from your feed.'),
        backgroundColor: const Color(0xFFFF9800), // warning color
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // 搜索动态
  void _searchPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        _filteredPosts = _userPosts;
      } else {
        _isSearching = true;
        _filteredPosts = _userPosts.where((post) {
          final postMsg = (post['postMsg'] ?? '').toLowerCase();
          final userName = (post['userName'] ?? '').toLowerCase();
          final searchQuery = query.toLowerCase();
          
          return postMsg.contains(searchQuery) || userName.contains(searchQuery);
        }).toList();
      }
    });
  }

  // 清除搜索
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filteredPosts = _userPosts;
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
            image: AssetImage('assets/images/xvibe_bg1.png'),
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
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // 搜索栏
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _searchPosts,
                                decoration: InputDecoration(
                                  hintText: 'Search posts or users...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (_isSearching)
                              GestureDetector(
                                onTap: _clearSearch,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // 如果正在搜索，显示搜索结果统计
                      if (_isSearching)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF24F8D5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF24F8D5).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_outlined,
                                color: const Color(0xFF24F8D5),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Found ${_filteredPosts.where((post) => !_hiddenPosts.contains(post['postId'])).length} results',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF24F8D5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_isSearching) const SizedBox(height: 16),

                      // 只有在非搜索状态下才显示顶部图片和热门话题
                      if (!_isSearching) ...[
                        // 顶部图片
                        Container(
                          height: 260,
                          margin: const EdgeInsets.only(left: 24, right: 24, top: 0),
                          child: Stack(
                            children: [
                              // 背景图片
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/kvibe_post_top.png',
                                  width: double.infinity,
                                  height: 260,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 260,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              // 热门话题列表叠加层
                              Positioned.fill(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                               
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                     
                                      const SizedBox(height: 46),
                                      
                                      // 话题列表
                                      Expanded(
                                        child: Column(
                                          children: _hotTopics.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final post = entry.value;
                                            return _buildOverlayHotTopicItem(index + 1, post);
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // 推荐文字图片
                        Container(
                          height: 43,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          child: Image.asset(
                            'assets/images/kvibe_post_recommend.png',
                            width: double.infinity,
                            height: 43,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 43,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Recommend',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                      
                      // 用户动态列表
                      _filteredPosts.isEmpty
                          ? Container(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSearching ? Icons.search_off : Icons.post_add,
                                      size: 48,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _isSearching ? 'No matching posts found' : 'No posts available',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (_isSearching) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try different keywords',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: _filteredPosts
                                    .where((post) => !_hiddenPosts.contains(post['postId']))
                                    .map((post) => _buildPostCard(post))
                                    .toList(),
                              ),
                            ),
                      
                      // 底部安全区域
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['postId'];
    final commentCount = _commentCounts[postId] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailPage(post: post),
                ),
              );
              
              // 返回时刷新数据
              if (result != null && result is Map<String, dynamic>) {
                if (result['hasAddedComment'] == true || result['hasLikeChanged'] == true) {
                  await _refreshPostData(postId);
                }
              }
            },
            child: Row(
              children: [
                // 用户头像
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF24F8D5),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      post['userPic'] ?? 'assets/images/default_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 用户名和时间
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(post['timestamp'] ?? 0),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 举报按钮
                GestureDetector(
                  onTap: () => _showReportPostDialog(post),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.report_outlined,
                          size: 16,
                          color: Colors.red[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Report',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 动态内容
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailPage(post: post),
                ),
              );
              
              // 返回时刷新数据
              if (result != null && result is Map<String, dynamic>) {
                if (result['hasAddedComment'] == true || result['hasLikeChanged'] == true) {
                  await _refreshPostData(postId);
                }
              }
            },
            child: Text(
              post['postMsg'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 视频缩略图
          if (post['playUrl'] != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      videoUrl: post['playUrl'] ?? '',
                      videoTitle: post['postMsg'] ?? 'Video',
                      post: post,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        post['userIcon'] ?? 'assets/images/default_video_thumb.png',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.video_library,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    // 播放按钮
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // 互动按钮行
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(postId),
                child: Row(
                  children: [
                    Icon(
                      (_likedPosts[postId] ?? false) ? Icons.favorite : Icons.favorite_border,
                      color: (_likedPosts[postId] ?? false) ? Colors.red : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _likeCounts[postId]?.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(post: post),
                    ),
                  );
                  
                  // 返回时刷新数据
                  if (result != null && result is Map<String, dynamic>) {
                    if (result['hasAddedComment'] == true || result['hasLikeChanged'] == true) {
                      await _refreshPostData(postId);
                    }
                  }
                },
                child: _buildActionButton(Icons.chat_bubble_outline, commentCount.toString(), Colors.blue),
              ),
              const Spacer(),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 24,
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayHotTopicItem(int number, Map<String, dynamic> post) {
    // 获取动态标题（截取前30个字符）
    String title = post['postMsg'] ?? 'No title';
    if (title.length > 35) {
      title = '${title.substring(0, 35)}...';
    }
    
    // 根据内容生成描述
    String description = _getTopicDescription(post['postMsg'] ?? '');
    
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(post: post),
          ),
        );
        
        // 返回时刷新数据
        if (result != null && result is Map<String, dynamic>) {
          if (result['hasAddedComment'] == true || result['hasLikeChanged'] == true) {
            await _refreshPostData(post['postId']);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 编号
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getNumberColor(number),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 10),
            
            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 根据编号获取颜色
  Color _getNumberColor(int number) {
    switch (number) {
      case 1:
        return const Color(0xFFFF6B6B); // 红色
      case 2:
        return const Color(0xFF4ECDC4); // 青色
      case 3:
        return const Color(0xFF45B7D1); // 蓝色
      default:
        return const Color(0xFF96CEB4); // 绿色
    }
  }

  // 根据动态内容生成描述
  String _getTopicDescription(String content) {
    if (content.toLowerCase().contains('meal') || content.toLowerCase().contains('food') || content.toLowerCase().contains('eat')) {
      return 'Star-endorsed style';
    } else if (content.toLowerCase().contains('workout') || content.toLowerCase().contains('fitness') || content.toLowerCase().contains('exercise')) {
      return 'Increase muscle and reduce fat';
    } else if (content.toLowerCase().contains('recipe') || content.toLowerCase().contains('cook') || content.toLowerCase().contains('healthy')) {
      return 'Quit Sugar';
    } else {
      return 'Health & Fitness Tips';
    }
  }
} 