import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/reward.dart';
import '../widgets/common.dart';
import '../widgets/member_badge.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key, required this.state});
  final AppState state;
  void showClaim(BuildContext context, RewardClaim claim, QuestReward reward) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('DEMO REWARD', color: green),
              const SizedBox(height: 16),
              Text(
                reward.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              SelectableText(
                claim.code,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sample code only. Not redeemable at a store. Real offers will be supplied by future partners.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DONE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> redeem(BuildContext context, QuestReward reward) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reward.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Use ${reward.cost} tokens to claim this demo offer?',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sample reward only · not a usable coupon yet.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheet, true),
                  child: Text('USE ${reward.cost} TOKENS'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(sheet, false),
                  child: const Text('CANCEL'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final claim = state.claimReward(reward.id);
    if (claim != null) showClaim(context, claim, reward);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: PageBody(
        children: [
          const SizedBox(height: 16),
          Panel(
            color: const Color(0xFFFFD166),
            child: Row(
              children: [
                const Icon(
                  Icons.toll_rounded,
                  color: Color(0xFFFFD166),
                  size: 34,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.tokenBalance} tokens',
                        key: const ValueKey('token-balance'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Earn tokens with verified quests.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1 token per 25 XP earned, with at least 1 per completion. Repeat quests earn fewer XP and tokens.',
            style: TextStyle(color: muted, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 26),
          const Eyebrow('PARTNER REWARDS · DEMO'),
          const SizedBox(height: 14),
          ...rewardCatalog.map((reward) {
            final claim = state.rewardClaims
                .where((c) => c.rewardId == reward.id)
                .firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(reward.icon, color: const Color(0xFFFFD166)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                reward.partner,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: claim != null
                            ? () => showClaim(context, claim, reward)
                            : state.tokenBalance >= reward.cost
                            ? () => redeem(context, reward)
                            : null,
                        child: Text(
                          claim != null
                              ? 'VIEW SAMPLE CODE'
                              : '${reward.cost} TOKENS',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Eyebrow('YOUR BADGES')),
              Text(
                '${state.equippedBadgeIds.length} / ${AppState.maxDisplayedBadges} displayed',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose up to three. Tap a selected badge to remove it.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...questBadges.map((badge) {
            final earned = state.hasBadge(badge.id),
                equipped = state.equippedBadgeIds.contains(badge.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: surface,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  key: ValueKey('badge-choice-${badge.id}'),
                  selected: equipped,
                  selectedTileColor: badge.color.withValues(alpha: .06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onTap: earned
                      ? () {
                          if (!state.toggleBadge(badge.id)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Choose up to three badges. Remove one to add another.',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  leading: Icon(
                    badge.icon,
                    color: earned ? badge.color : muted,
                  ),
                  title: earned
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: MemberBadge(badge: badge),
                        )
                      : Text(
                          badge.title,
                          style: const TextStyle(fontSize: 14, color: muted),
                        ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      badge.requirement,
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                  ),
                  trailing: equipped
                      ? const Text(
                          'Selected',
                          style: TextStyle(color: green, fontSize: 11),
                        )
                      : earned
                      ? const Icon(Icons.add_rounded, size: 18, color: muted)
                      : const Icon(
                          Icons.lock_outline_rounded,
                          size: 17,
                          color: muted,
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}
