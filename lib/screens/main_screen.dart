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
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final navigationOpacity = Tween<double>(
    begin: .75,
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

  Widget buildDrawer(BuildContext context) {
    final auth = AccountScope.of(context);
    return Drawer(
      backgroundColor: surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.route_rounded, color: green, size: 34),
                  const SizedBox(height: 16),
                  const Text(
                    'SideQuest',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth?.account?.email ?? 'Local preview',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Account'),
              onTap: () =>
                  openMenuPage(AccountScreen(auth: auth, state: widget.state)),
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Activity Log'),
              onTap: () => openMenuPage(
                Scaffold(
                  appBar: AppBar(title: const Text('Activity Log')),
                  body: ListenableBuilder(
                    listenable: widget.state,
                    builder: (_, _) => ActivityLogScreen(
                      state: widget.state,
                      openQuest: openQuest,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => openMenuPage(SettingsScreen(state: widget.state)),
            ),
            const Spacer(),
            const Divider(color: raised),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(auth == null ? 'Exit preview' : 'Log out'),
              onTap: () async {
                Navigator.pop(context);
                await widget.state.historySaved;
                if (auth != null) {
                  try {
                    await auth.signOut();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not log out. Please retry.'),
                        ),
                      );
                    }
                  }
                } else if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void returnHome() {
    selectTab(0);
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
        title: const Text(
          'SideQuest',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: green,
          ),
        ),
      ),
      drawer: buildDrawer(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: navigationOpacity,
          child: IndexedStack(
            index: tab,
            children: [
              HomeScreen(
                state: widget.state,
                openQuest: openQuest,
                openFriends: () => selectTab(3),
              ),
              QuestsScreen(state: widget.state, openQuest: openQuest),
              ProgressScreen(state: widget.state),
              FriendsScreen(state: widget.state, openQuest: openQuest),
            ],
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
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final quests = widget.state.quests
          .where((q) => filter == null || q.categories.contains(filter))
          .where(
            (q) =>
                widget.state.showCompletedQuests ||
                !q.isCompleted ||
                q.isActive,
          )
          .toList();
      return PageBody(
        children: [
          const PageHeading('Explore', 'Find your next SideQuest.'),
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
