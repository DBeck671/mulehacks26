import 'dart:math';

import 'package:flutter/material.dart';

import 'verification.dart';

enum Category { nature, creativity, learning, exploration, wellness, food }

extension CategoryStyle on Category {
  String get label => name[0].toUpperCase() + name.substring(1);
  Color get color => const [
    Color(0xFF62D26F),
    Color(0xFFA879FF),
    Color(0xFF5DA9FF),
    Color(0xFFFF9F43),
    Color(0xFFFF6B8A),
    Color(0xFFFFD166),
  ][index];
  IconData get icon => const [
    Icons.eco_outlined,
    Icons.palette_outlined,
    Icons.menu_book_rounded,
    Icons.explore_outlined,
    Icons.favorite_outline,
    Icons.restaurant_rounded,
  ][index];
}

class Quest {
  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.categories,
    required this.xp,
    required this.verification,
    this.duration = '30 min',
    this.difficulty = 'Easy',
    this.isCompleted = false,
    this.isLocked = false,
    this.isNew = false,
    this.isActive = false,
  }) {
    if (isActive) attemptClock.start();
  }
  final Stopwatch attemptClock = Stopwatch();
  Duration? get targetDuration {
    final minutes = RegExp(r'^(\d+) min$').firstMatch(duration);
    return minutes == null
        ? null
        : Duration(minutes: int.parse(minutes.group(1)!));
  }

  final int id;
  final String title, description, duration, difficulty;
  final List<Category> categories;
  final int xp;
  final Verification verification;
  // isCompleted remembers lifetime completion history; isActive describes this attempt.
  int completionCount = 0;
  int earnedXP = 0;
  int get rewardXP => completionCount == 0 ? xp : max(1, xp ~/ 2);
  int attemptNumber = 0;
  bool isCompleted, isLocked, isNew, isActive;
  Color get color => categories.first.color;
  String get status => isActive
      ? 'Active'
      : isCompleted
      ? 'Completed'
      : isLocked
      ? 'Locked'
      : isNew
      ? 'New'
      : 'Available';
}
