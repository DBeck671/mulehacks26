import 'package:flutter/material.dart';

class QuestReward {
  const QuestReward(this.id, this.title, this.partner, this.cost, this.icon);
  final String id, title, partner;
  final int cost;
  final IconData icon;
}

// Sample offers only. No sponsor or redeemable commercial coupon is implied.
const rewardCatalog = [
  QuestReward(
    'coffee',
    'A coffee on us',
    'Café partner · sample offer',
    8,
    Icons.local_cafe_outlined,
  ),
  QuestReward(
    'books',
    '20% off your next book',
    'Bookshop partner · sample offer',
    16,
    Icons.auto_stories_outlined,
  ),
  QuestReward(
    'outdoors',
    '15% off outdoor gear',
    'Outdoor partner · sample offer',
    24,
    Icons.landscape_outlined,
  ),
];

class RewardClaim {
  const RewardClaim({
    required this.rewardId,
    required this.cost,
    required this.code,
    required this.claimedAt,
  });
  final String rewardId, code;
  final int cost;
  final DateTime claimedAt;
  Map<String, Object> toJson() => {
    'rewardId': rewardId,
    'cost': cost,
    'code': code,
    'claimedAt': claimedAt.toUtc().toIso8601String(),
  };
  factory RewardClaim.fromJson(Map<String, dynamic> data) => RewardClaim(
    rewardId: data['rewardId'] as String,
    cost: data['cost'] as int,
    code: data['code'] as String,
    claimedAt: DateTime.parse(data['claimedAt'] as String),
  );
}

class QuestBadge {
  const QuestBadge(
    this.id,
    this.title,
    this.requirement,
    this.icon,
    this.color,
  );
  final String id, title, requirement;
  final IconData icon;
  final Color color;
}

const questBadges = [
  QuestBadge(
    'first',
    'First steps',
    'Complete your first quest.',
    Icons.directions_walk_rounded,
    Color(0xFF62D26F),
  ),
  QuestBadge(
    'connected',
    'Connected',
    'Discover your first connection.',
    Icons.hub_outlined,
    Color(0xFF62D26F),
  ),
  QuestBadge(
    'explorer',
    'Explorer',
    'Complete 5 Exploration quests.',
    Icons.explore_outlined,
    Color(0xFFFF9F43),
  ),
  QuestBadge(
    'creative',
    'Creative mind',
    'Complete 5 Creativity quests.',
    Icons.palette_outlined,
    Color(0xFFA879FF),
  ),
  QuestBadge(
    'adventurer',
    'Adventurer',
    'Complete 10 quests.',
    Icons.landscape_outlined,
    Color(0xFF5DA9FF),
  ),
  QuestBadge(
    'leader',
    'Friendly competition',
    'Reach #1 in your club.',
    Icons.emoji_events_outlined,
    Color(0xFFFFD166),
  ),
  QuestBadge(
    'pathfinder',
    'Pathfinder',
    'Unlock 10 activities.',
    Icons.route_outlined,
    Color(0xFFFF6B8A),
  ),
];
