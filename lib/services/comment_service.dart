import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class CommentService {
  static const String _keyPrefix = 'comments_';
  
  // 减脂相关评论模板
  static final List<String> _fitnessComments = [
    "Great motivation! I've been following a similar routine and it's really working!",
    "This is exactly what I needed to see today. Thanks for sharing your journey!",
    "Amazing progress! What's your diet plan like?",
    "Love seeing fitness content like this. Keep up the great work!",
    "This inspires me to get back to my workout routine. Thank you!",
    "Your dedication is incredible! How long have you been at it?",
    "Such good tips! I'm definitely going to try this approach.",
    "Consistency is key! You're doing amazing, keep it up!",
    "This post came at the perfect time. Starting my fitness journey tomorrow!",
    "Your transformation is so inspiring! What supplements do you recommend?",
    "I've been struggling with motivation lately, this really helps!",
    "The results speak for themselves! What's your favorite exercise?",
    "This is the push I needed to get back on track with my health goals.",
    "Amazing work! How do you stay motivated on tough days?",
    "Your fitness journey is so inspiring! Thanks for sharing these tips.",
    "I love how you break down the process. Makes it seem so achievable!",
    "This is exactly the kind of content we need more of!",
    "Your progress pics are incredible! What's your secret?",
    "Been following your journey for a while now, keep crushing it!",
    "This post is pure motivation! Screenshot saved for tough days.",
  ];

  // 随机用户名
  static final List<String> _randomUsernames = [
    "FitLife_Sarah", "HealthyMike", "GymRat_Jenny", "WellnessWarrior", "FitMom_Lisa",
    "IronWill_Tom", "HealthyHabits", "FitnessFirst", "StrongMind_Alex", "HealthJourney",
    "FitAndFab", "WellnessWin", "HealthyChoice", "FitLife_Coach", "StrengthSeeker",
    "HealthyVibes", "FitnessFreak", "WellnessWay", "HealthGoals", "FitForLife",
  ];

  // 获取评论数量
  static Future<int> getCommentCount(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? commentsJson = prefs.getString('$_keyPrefix$postId');
      
      if (commentsJson != null) {
        final List<dynamic> commentsList = json.decode(commentsJson);
        return commentsList.length;
      } else {
        // 如果没有评论数据，生成初始评论并返回数量
        final comments = await _generateInitialComments(postId);
        return comments.length;
      }
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

  // 获取评论列表
  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? commentsJson = prefs.getString('$_keyPrefix$postId');
      
      if (commentsJson != null) {
        final List<dynamic> commentsList = json.decode(commentsJson);
        return commentsList.cast<Map<String, dynamic>>();
      } else {
        // 第一次访问，生成初始评论
        return await _generateInitialComments(postId);
      }
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // 生成初始评论
  static Future<List<Map<String, dynamic>>> _generateInitialComments(String postId) async {
    final random = Random(postId.hashCode); // 使用postId作为随机种子，确保一致性
    final commentCount = random.nextInt(10) + 1; // 1-10条评论
    
    List<Map<String, dynamic>> initialComments = [];
    List<String> usedComments = [];
    List<String> usedUsernames = [];
    
    for (int i = 0; i < commentCount; i++) {
      // 确保不重复评论内容
      String comment;
      do {
        comment = _fitnessComments[random.nextInt(_fitnessComments.length)];
      } while (usedComments.contains(comment) && usedComments.length < _fitnessComments.length);
      usedComments.add(comment);
      
      // 确保不重复用户名
      String username;
      do {
        username = _randomUsernames[random.nextInt(_randomUsernames.length)];
      } while (usedUsernames.contains(username) && usedUsernames.length < _randomUsernames.length);
      usedUsernames.add(username);
      
      // 生成随机时间戳（过去1-7天内）
      final hoursAgo = random.nextInt(168) + 1; // 1-168小时前（1-7天）
      final timestamp = DateTime.now().subtract(Duration(hours: hoursAgo)).millisecondsSinceEpoch;
      
      initialComments.add({
        'id': 'initial_${i}_$postId',
        'text': comment,
        'author': username,
        'authorAvatar': 'assets/images/default_avatar.png',
        'timestamp': timestamp,
      });
    }
    
    // 按时间排序（最新的在前面）
    initialComments.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    // 保存到本地存储
    await _saveComments(postId, initialComments);
    
    return initialComments;
  }

  // 保存评论
  static Future<void> _saveComments(String postId, List<Map<String, dynamic>> comments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String commentsJson = json.encode(comments);
      await prefs.setString('$_keyPrefix$postId', commentsJson);
    } catch (e) {
      print('Error saving comments: $e');
    }
  }

  // 添加评论
  static Future<void> addComment(String postId, Map<String, dynamic> comment) async {
    try {
      final comments = await getComments(postId);
      comments.insert(0, comment);
      await _saveComments(postId, comments);
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  // 获取点赞数量
  static Future<int> getLikeCount(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? likeCountStr = prefs.getString('like_count_$postId');
      
      if (likeCountStr != null) {
        return int.parse(likeCountStr);
      } else {
        // 第一次访问，生成初始点赞数
        return await _generateInitialLikeCount(postId);
      }
    } catch (e) {
      print('Error getting like count: $e');
      return 0;
    }
  }

  // 生成初始点赞数量
  static Future<int> _generateInitialLikeCount(String postId) async {
    final random = Random(postId.hashCode); // 使用postId作为随机种子，确保一致性
    final likeCount = random.nextInt(401) + 100; // 100-500的随机数
    
    // 保存到本地存储
    await _saveLikeCount(postId, likeCount);
    
    return likeCount;
  }

  // 保存点赞数量
  static Future<void> _saveLikeCount(String postId, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('like_count_$postId', count.toString());
    } catch (e) {
      print('Error saving like count: $e');
    }
  }

  // 更新点赞数量
  static Future<void> updateLikeCount(String postId, int newCount) async {
    await _saveLikeCount(postId, newCount);
  }

  // 获取用户点赞状态
  static Future<bool> isLiked(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('liked_$postId') ?? false;
    } catch (e) {
      print('Error getting like status: $e');
      return false;
    }
  }

  // 设置用户点赞状态
  static Future<void> setLiked(String postId, bool isLiked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('liked_$postId', isLiked);
    } catch (e) {
      print('Error setting like status: $e');
    }
  }
} 