import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../widgets/common.dart';
import '../widgets/home_leaderboard.dart';
import '../widgets/quest_row_card.dart';
import 'quest_detail_screen.dart';
import 'activity_log_screen.dart';
import 'friends_screen.dart';
import 'progress_screen.dart';
import '../auth/auth_gate.dart';
import 'account_screen.dart';
import 'settings_screen.dart';
import 'rewards_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.state});
  final AppState state;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final navigationFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  late final navigationOpacity = Tween<double>(
    begin: .45,
    end: 1,
  ).animate(CurvedAnimation(parent: navigationFade, curve: Curves.easeOut));
  void selectTab(int next) {
    if (next == tab) return;
    setState(() => tab = next);
    if (!MediaQuery.disableAnimationsOf(context)) {
      navigationFade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    navigationFade.dispose();
    super.dispose();
  }

  int tab = 0;
  void openMenuPage(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void openAccountMenu() {
    final auth = AccountScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  widget.state.profileName.isEmpty
                      ? 'Your account'
                      : widget.state.profileName,
                ),
                subtitle: Text(
                  auth?.account?.email ?? 'Local preview',
                  style: const TextStyle(color: muted),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Account'),
                onTap: () => openMenuPage(
                  AccountScreen(auth: auth, state: widget.state),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () => openMenuPage(SettingsScreen(state: widget.state)),
              ),
              ListTile(
                leading: const Icon(Icons.toll_rounded),
                title: const Text('Rewards & badges'),
                subtitle: Text('${widget.state.tokenBalance} tokens'),
                onTap: () => openMenuPage(RewardsScreen(state: widget.state)),
              ),
              if (auth != null)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log out'),
                  onTap: () async {
                    Navigator.pop(context);
                    await widget.state.historySaved;
                    try {
                      await auth.signOut();
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not log out. Please retry.'),
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void returnHome() {
    selectTab(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void returnQuests() {
    selectTab(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void openQuest(Quest quest) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestDetailScreen(
          state: widget.state,
          quest: quest,
          onReturnHome: returnHome,
          onStopTask: returnQuests,
        ),
      ),
    );
    if (completed == true && mounted) selectTab(0);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (_, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Account menu',
            onPressed: openAccountMenu,
            icon: const Icon(Icons.account_circle_outlined, size: 22),
          ),
          if (widget.state.showcaseMode) ...[
            const Center(
              child: Text('DEMO', style: TextStyle(color: muted, fontSize: 10)),
            ),
            IconButton(
              tooltip: widget.state.audio.enabled
                  ? 'Mute sounds'
                  : 'Enable sounds',
              onPressed: () =>
                  widget.state.setSoundEnabled(!widget.state.audio.enabled),
              icon: Icon(
                widget.state.audio.enabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                size: 20,
              ),
            ),
          ],
        ],
        title: const Text(
          'SideQuest',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: green,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: navigationOpacity,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, .015),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: navigationFade,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: IndexedStack(
              index: tab,
              children: [
                HomeScreen(
                  state: widget.state,
                  openQuest: openQuest,
                  openFriends: () => selectTab(4),
                ),
                QuestsScreen(state: widget.state, openQuest: openQuest),
                TickerMode(
                  enabled: tab == 2,
                  child: ProgressScreen(state: widget.state),
                ),
                ActivityLogScreen(state: widget.state, openQuest: openQuest),
                FriendsScreen(state: widget.state, openQuest: openQuest),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: selectTab,
        height: 76,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: muted),
            selectedIcon: Icon(Icons.home_rounded, color: green),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: muted),
            selectedIcon: Icon(Icons.explore_rounded, color: green),
            label: 'Quests',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: muted),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: green),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded, color: muted),
            selectedIcon: Icon(Icons.history_rounded, color: green),
            label: 'Activity Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: muted),
            selectedIcon: Icon(Icons.groups_rounded, color: green),
            label: 'Friends',
          ),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.openQuest,
    required this.openFriends,
  });
  final AppState state;
  final ValueChanged<Quest> openQuest;
  final VoidCallback openFriends;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text(
        'Ready for your\nnext adventure?',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 12),
      const Text('', style: TextStyle(color: muted, fontSize: 13)),
      const SizedBox(height: 26),
      XPBar(totalXP: state.totalXP),
      const SizedBox(height: 32),
      Row(
        children: [
          const Expanded(child: Eyebrow("TODAY'S SIDEQUEST")),
          TextButton(
            onPressed: state.newQuest,
            child: const Row(
              children: [
                Icon(Icons.shuffle_rounded, size: 14),
                SizedBox(width: 6),
                Text('New SideQuest', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      QuestCard(
        quest: state.active ?? state.featured,
        featured: true,
        onTap: () => openQuest(state.active ?? state.featured),
      ),
      const SizedBox(height: 24),
      HomeLeaderboard(state: state, openFriends: openFriends),
    ],
  );
}

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key, required this.state, required this.openQuest});
  final AppState state;
  final ValueChanged<Quest> openQuest;
  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  Category? filter;
  bool activeOnly = false;
  Timer? ticker;
  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && activeOnly && widget.state.activeQuests.isNotEmpty) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final quests = widget.state.quests
          .where(
            (q) => activeOnly
                ? q.isActive
                : filter == null || q.categories.contains(filter),
          )
          .where(
            (q) =>
                widget.state.showCompletedQuests ||
                !q.isCompleted ||
                q.isActive,
          )
          .toList();
      return PageBody(
        children: [
          const PageHeading('Quests', ''),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(value: false, label: Text('Explore')),
              ButtonSegment(
                value: true,
                label: Text('Active (${widget.state.activeQuests.length})'),
              ),
            ],
            selected: {activeOnly},
            onSelectionChanged: (value) =>
                setState(() => activeOnly = value.first),
          ),
          const SizedBox(height: 18),
          if (!activeOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButton<Category?>(
                value: filter,
                isExpanded: true,
                hint: const Text('All categories'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<Category?>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...Category.values.map(
                    (c) => DropdownMenuItem<Category?>(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, color: c.color, size: 18),
                          const SizedBox(width: 10),
                          Text(c.label),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (category) => setState(() {
                  filter = category;
                }),
              ),
            ),
          const SizedBox(height: 18),
          if (activeOnly && quests.isEmpty)
            const Panel(
              child: Text(
                'No active sidequests. Choose one in Explore.',
                style: TextStyle(color: muted),
              ),
            ),
          ...quests.map(
            (quest) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuestRowCard(
                quest: quest,
                onTap: () => widget.openQuest(quest),
              ),
            ),
          ),
        ],
      );
    },
  );
}
