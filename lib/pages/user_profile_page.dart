import 'package:flutter/material.dart';
import 'dart:math';
import '../services/follow_service.dart';
import '../services/block_service.dart';
import '../services/comment_service.dart';
import '../models/user_model.dart';
import '../pages/chat_page.dart';
import '../pages/post_detail_page.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isFollowing = false;
  bool _isBlocked = false;
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    // 基于实际用户数据生成统计信息
    List<dynamic> userPosts = widget.user['post'] ?? [];
    _postsCount = userPosts.length;
    
    // 生成用户ID（使用用户名作为唯一标识）
    String userId = widget.user['name'] ?? 'unknown_user';
    
    // 检查关注状态
    _isFollowing = await FollowService.isFollowing(userId);
    
    // 检查拉黑状态
    _isBlocked = await BlockService.isUserBlocked(userId);
    
    // 获取或设置粉丝数
    int initialFollowersCount = Random().nextInt(1000) + 100;
    await FollowService.setInitialFollowersCount(userId, initialFollowersCount);
    _followersCount = await FollowService.getFollowersCount(userId);
    
    // 生成关注数（这个数据在JSON中没有，所以保持随机）
    _followingCount = Random().nextInt(1000) + 50;
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleFollow() async {
    String userId = widget.user['name'] ?? 'unknown_user';
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_isFollowing) {
        await FollowService.unfollowUser(userId);
      } else {
        await FollowService.followUser(userId);
      }
      
      // 更新本地状态
      _isFollowing = !_isFollowing;
      _followersCount = await FollowService.getFollowersCount(userId);
      
    } catch (e) {
      // 处理错误
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleBlock() async {
    String userId = widget.user['name'] ?? 'unknown_user';
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_isBlocked) {
        await BlockService.unblockUser(userId);
        _isBlocked = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unblocked'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await BlockService.blockUser(userId);
        _isBlocked = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.report,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Report User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please select a reason for reporting:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildReportOption('Inappropriate content'),
              _buildReportOption('Harassment'),
              _buildReportOption('False information'),
              _buildReportOption('Spam'),
              _buildReportOption('Other reasons'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportOption(String reason) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _submitReport(reason);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          reason,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  void _submitReport(String reason) {
    // 这里可以实现真实的举报提交逻辑
    // 比如发送到服务器等
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report submitted: $reason'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部指示条
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 拉黑选项
              ListTile(
                leading: Icon(
                  _isBlocked ? Icons.person_add : Icons.block,
                  color: _isBlocked ? Colors.green : Colors.orange,
                  size: 24,
                ),
                title: Text(
                  _isBlocked ? 'Unblock' : 'Block User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isBlocked ? Colors.green : Colors.orange,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleBlock();
                },
              ),
              
              const Divider(height: 1),
              
              // 举报选项
              ListTile(
                leading: const Icon(
                  Icons.report,
                  color: Colors.red,
                  size: 24,
                ),
                title: const Text(
                  'Report User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // 顶部背景图片 - 从最顶部开始
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity, // 确保宽度铺满
                height: 300, // 背景图片高度
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/kvibe_userdetail_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // 原有的页面背景（在背景图片下方）
            Positioned(
              top: 250, // 从背景图片中间开始渐变
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/xvibe_bg1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // 页面内容
            SafeArea(
              child: Column(
                children: [
                  // 顶部导航栏
                  _buildAppBar(),
                  
                  // 可滚动内容
                  Expanded(
                    child: _isLoading 
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF24F8D5)),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              // 用户基本信息
                              _buildUserHeader(),
                              
                              // 统计信息
                              _buildStatsSection(),
                              
                              // 用户介绍
                              _buildBioSection(),
                              
                              // 关注按钮
                              _buildFollowButton(),
                              
                              // 分隔线
                              const Divider(
                                height: 32,
                                thickness: 1,
                                color: Colors.white30,
                                indent: 16,
                                endIndent: 16,
                              ),
                              
                              // 用户动态标题
                              _buildPostsHeader(),
                              
                              // 用户动态列表
                              _buildPostsList(),
                            ],
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
          
          const Spacer(),
          
          // 更多选项按钮
          GestureDetector(
            onTap: _showMoreOptions,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40), // 给顶部导航栏留出空间
          
          // 用户头像
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF24F8D5), width: 3),
              color: Colors.white,
            ),
            child: ClipOval(
              child: widget.user['userpic'] != null
                  ? Image.asset(
                      widget.user['userpic'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[600],
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey[600],
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 用户名
          Text(
            widget.user['name'] ?? 'Unknown User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Posts', _postsCount.toString()),
          _buildStatDivider(),
          _buildStatItem('Followers', _formatCount(_followersCount)),
          _buildStatDivider(),
          _buildStatItem('Following', _formatCount(_followingCount)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[300],
    );
  }

  Widget _buildBioSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.user['introduction'] ?? 'No introduction available.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Follow按钮
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey[400] : const Color(0xFF24F8D5),
                foregroundColor: _isFollowing ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isFollowing ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          // 只有在未被拉黑时才显示聊天按钮
          if (!_isBlocked) ...[
            const SizedBox(width: 12), // 两个按钮之间的间距
            
            // Chat按钮
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // 将用户数据转换为UserModel
                  final userModel = UserModel.fromJson(widget.user);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(user: userModel),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            // 被拉黑时显示提示信息
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: const Text(
                  'Blocked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Posts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            '$_postsCount posts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    // 获取用户的实际动态数据
    List<dynamic> userPosts = widget.user['post'] ?? [];
    
    if (userPosts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user hasn\'t shared any posts',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: userPosts.length,
        itemBuilder: (context, index) {
          final post = userPosts[index];
          final postId = post['postId'] ?? 'post_${widget.user['userId']}_$index';
          
          return FutureBuilder<Map<String, int>>(
            future: _getPostStats(postId),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {'likes': 0, 'comments': 0};
              
              return GestureDetector(
                onTap: () async {
                  // 构造完整的动态数据结构用于传递到详情页
                  final postData = {
                    'postId': postId,
                    'postMsg': post['postmsg'] ?? post['postMsg'] ?? '',
                    'playUrl': post['playUrl'],
                    'userName': widget.user['name'] ?? 'Unknown User',
                    'userPic': widget.user['userpic'] ?? 'assets/images/default_avatar.png',
                    'userIcon': widget.user['userIcon'] ?? widget.user['userpic'] ?? 'assets/images/default_avatar.png',
                    'timestamp': DateTime.now().millisecondsSinceEpoch - (index * 3600000), // 模拟不同时间
                  };
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(post: postData),
                    ),
                  );
                  
                  // 如果从详情页返回且有数据变化，刷新当前页面
                  if (result != null && (result['hasAddedComment'] == true || result['hasLikeChanged'] == true)) {
                    setState(() {
                      // 触发重新构建以更新数据
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 动态图片/视频缩略图
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            child: Stack(
                              children: [
                                // 使用用户头像作为内容图片，或者用户背景图
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: widget.user['userpicBg'] != null
                                      ? Image.asset(
                                          widget.user['userpicBg'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return widget.user['userpic'] != null
                                                ? Image.asset(
                                                    widget.user['userpic'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[300],
                                                        child: Icon(
                                                          Icons.image,
                                                          size: 30,
                                                          color: Colors.grey[600],
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.image,
                                                      size: 30,
                                                      color: Colors.grey[600],
                                                    ),
                                                  );
                                          },
                                        )
                                      : widget.user['userpic'] != null
                                          ? Image.asset(
                                              widget.user['userpic'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 30,
                                                    color: Colors.grey[600],
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.image,
                                                size: 30,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                ),
                                
                                // 视频播放图标（如果有视频URL）
                                if (post['playUrl'] != null)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // 动态信息
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 动态内容
                                Expanded(
                                  child: Text(
                                    post['postmsg'] ?? 'No content',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                      height: 1.3,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // 底部互动信息 - 使用真实数据
                                Row(
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 12,
                                      color: Colors.red[400],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${stats['likes']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${stats['comments']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                   
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
          );
        },
      ),
    );
  }

  // 获取动态的统计数据（点赞数和评论数）
  Future<Map<String, int>> _getPostStats(String postId) async {
    try {
      final likeCount = await CommentService.getLikeCount(postId);
      final comments = await CommentService.getComments(postId);
      
      return {
        'likes': likeCount,
        'comments': comments.length,
      };
    } catch (e) {
      print('Error getting post stats: $e');
      return {
        'likes': 0,
        'comments': 0,
      };
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
} 