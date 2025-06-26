import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class FollowService {
  static const String _followedUsersKey = 'followed_users';
  static const String _followersCountKey = 'followers_count_';
  
  // 获取已关注的用户列表
  static Future<List<String>> getFollowedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_followedUsersKey) ?? [];
  }
  
  // 检查是否已关注某个用户
  static Future<bool> isFollowing(String userId) async {
    final followedUsers = await getFollowedUsers();
    return followedUsers.contains(userId);
  }
  
  // 关注用户
  static Future<void> followUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final followedUsers = await getFollowedUsers();
    
    if (!followedUsers.contains(userId)) {
      followedUsers.add(userId);
      await prefs.setStringList(_followedUsersKey, followedUsers);
      
      // 增加该用户的粉丝数
      await _incrementFollowersCount(userId);
    }
  }
  
  // 取消关注用户
  static Future<void> unfollowUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final followedUsers = await getFollowedUsers();
    
    if (followedUsers.contains(userId)) {
      followedUsers.remove(userId);
      await prefs.setStringList(_followedUsersKey, followedUsers);
      
      // 减少该用户的粉丝数
      await _decrementFollowersCount(userId);
    }
  }
  
  // 获取用户的粉丝数
  static Future<int> getFollowersCount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_followersCountKey$userId') ?? 0;
  }
  
  // 设置用户的初始粉丝数
  static Future<void> setInitialFollowersCount(String userId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final existingCount = prefs.getInt('$_followersCountKey$userId');
    
    // 只有在没有设置过的情况下才设置初始值
    if (existingCount == null) {
      await prefs.setInt('$_followersCountKey$userId', count);
    }
  }
  
  // 增加粉丝数
  static Future<void> _incrementFollowersCount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getFollowersCount(userId);
    await prefs.setInt('$_followersCountKey$userId', currentCount + 1);
  }
  
  // 减少粉丝数
  static Future<void> _decrementFollowersCount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getFollowersCount(userId);
    await prefs.setInt('$_followersCountKey$userId', math.max(0, currentCount - 1));
  }
  
  // 清除所有关注数据（用于测试或重置）
  static Future<void> clearAllFollowData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (String key in keys) {
      if (key.startsWith(_followedUsersKey) || key.startsWith(_followersCountKey)) {
        await prefs.remove(key);
      }
    }
  }
} 