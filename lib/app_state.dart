import 'dart:math';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import 'data/sample_quests.dart';
import 'services/quest_audio.dart';
import 'services/photo_verifier.dart';
import 'services/firebase_photo_verifier.dart';
import 'data/activity_store.dart';
import 'models/quest.dart';
import 'models/completed_activity.dart';
import 'models/connection.dart';
import 'models/activity_node.dart';
import 'models/friend.dart';
import 'models/group.dart';
import 'models/club_message.dart';
import 'models/party_task.dart';
import 'models/location_check_in.dart';
import 'models/verification.dart';

class ClubCompletion {
  ClubCompletion({
    required this.groupId,
    required this.round,
    required this.name,
    required this.taskIds,
    required this.completedIds,
  });
  final int groupId, round;
  final String name;
  final List<int> taskIds, completedIds;
  bool get isComplete => completedIds.length == taskIds.length;
}

class CompletionResult {
  CompletionResult(
    this.quest,
    this.oldXP,
    this.newXP,
    this.unlocked,
    this.connections, {
    this.club,
  });
  final Quest quest;
  final int oldXP, newXP;
  int get awardedXP => newXP - oldXP;
  final List<Quest> unlocked;
  final List<Connection> connections;
  final ClubCompletion? club;
}

// One small ChangeNotifier owns the entire local demo. Screens only read it
// and call these methods, so tab changes never reset gameplay progress.
enum JoinGroupResult { joined, alreadyActive, invalidCode, unknownCode }

class AppState extends ChangeNotifier {
  AppState({
    Random? recommendationRandom,
    this.activityStore,
    this.photoVerifier = const FirebasePhotoVerifier(),
    this.demoData = false,
    this.showcaseMode = false,
  }) : _recommendationRandom = recommendationRandom ?? Random() {
    if (showcaseMode && !demoData) {
      throw ArgumentError('Showcase requires isolated demo data');
    }
    audio.enabled = showcaseMode;
    player = initialGroup.members.firstWhere((f) => f.id == 0);
    if (!demoData) {
      player.xp = 0;
      player.questsCompleted = 0;
      joinedGroupIds.clear();
      activeGroupId = null;
      return;
    }
    totalXP = 3780;
    groups.add(initialGroup);
    _generatePartyTasks(initialGroup);
    groups.add(
      Group(
        id: 2,
        name: 'Curiosity Club',
        members: initialGroup.members
            .map(
              (f) => f.id == 0
                  ? you
                  : Friend(
                      id: f.id,
                      name: f.name,
                      xp: f.xp,
                      avatarInitial: f.avatarInitial,
                      questsCompleted: f.questsCompleted,
                    ),
            )
            .toList(),
        groupCode: 'SQ-7319',
        inviteCode: 'INV-7319',
      ),
    );
  }
  PhotoVerifier photoVerifier;
  final bool demoData;
  final bool showcaseMode;
  final QuestAudio audio = QuestAudio();
  void setSoundEnabled(bool enabled) {
    audio.enabled = enabled;
    _saveHistory();
    notifyListeners();
  }

  bool simulateVerification(Quest q) {
    if (!showcaseMode || !q.isActive || q.isLocked) return false;
    q.verification.demoVerified = true;
    notifyListeners();
    return true;
  }

  final Map<int, List<ClubMessage>> _clubMessages = {};
  final Set<Timer> _chatTimers = {};
  List<ClubMessage> clubMessages(int groupId) =>
      List.unmodifiable(_clubMessages[groupId] ?? const <ClubMessage>[]);

  bool sendClubMessage(int groupId, String text) {
    final content = text.trim();
    if (_disposed ||
        !joinedGroupIds.contains(groupId) ||
        content.isEmpty ||
        content.length > 500) {
      return false;
    }
    final club = groups.firstWhere((g) => g.id == groupId);
    final messages = _clubMessages.putIfAbsent(groupId, () => []);
    messages.add(
      ClubMessage(
        sender: you.name,
        text: content,
        sentAt: DateTime.now(),
        isYou: true,
      ),
    );
    notifyListeners();
    if (showcaseMode && club.members.any((m) => m.id != 0)) {
      final friend = club.members.firstWhere((m) => m.id != 0);
      late Timer timer;
      timer = Timer(const Duration(seconds: 2), () {
        _chatTimers.remove(timer);
        if (_disposed || !joinedGroupIds.contains(groupId)) return;
        final remaining = club.partyTasks.where((t) => !t.isCompleted).toList();
        messages.add(
          ClubMessage(
            sender: friend.name,
            isBot: true,
            sentAt: DateTime.now(),
            text: remaining.isEmpty
                ? 'We finished this round! Ready for another?'
                : 'Let’s work on ${quest(remaining.first.questId).title} next. We have ${remaining.length} shared tasks left.',
          ),
        );
        notifyListeners();
      });
      _chatTimers.add(timer);
    }
    return true;
  }

  int _botTurn = 0;
  Timer? _botTimer;
  bool demoBotsRunning = false;
  final Map<int, List<String>> _demoClubActivity = {};
  List<String> get clubRecentActivity =>
      hasGroup ? (_demoClubActivity[group.id] ?? []) : recentActivity;

  void _fillDemoFriends(Group club) {
    if (!showcaseMode) return;
    const names = ['Alex', 'Jordan', 'Sam', 'Chris'];
    for (var i = 0; i < names.length; i++) {
      final id = i + 1;
      if (!club.members.any((f) => f.id == id)) {
        club.members.add(
          Friend(
            id: id,
            name: names[i],
            xp: 0,
            avatarInitial: names[i][0],
            questsCompleted: 0,
          ),
        );
      }
    }
  }

  void setDemoBotsRunning(bool running) {
    if (!showcaseMode) return;
    _botTimer?.cancel();
    demoBotsRunning = running;
    if (running) {
      for (final club in groups) {
        _fillDemoFriends(club);
      }
      simulateFriendCompletion();
      _botTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        if (!_disposed) simulateFriendCompletion();
      });
    }
    notifyListeners();
  }

  bool simulateFriendCompletion() {
    if (!showcaseMode || !hasGroup) return false;
    final task = group.partyTasks
        .where((t) => !t.isCompleted && !quest(t.questId).isActive)
        .firstOrNull;
    final bots = group.members.where((f) => f.id != 0).toList();
    if (task == null || bots.isEmpty) return false;
    final bot = bots[_botTurn++ % bots.length];
    final q = quest(task.questId);
    task.completedById = bot.id;
    task.completedByName = '${bot.name} (bot)';
    task.completedAt = DateTime.now();
    task.earnedXP = q.rewardXP;
    bot.xp += task.earnedXP;
    bot.questsCompleted++;
    if (group.weeklyChallengeProgress < group.weeklyChallengeGoal) {
      group.weeklyChallengeProgress++;
    }
    final entry =
        '${bot.name} (bot) completed ${q.title} · +${task.earnedXP} XP';
    recentActivity.insert(0, entry);
    _demoClubActivity.putIfAbsent(group.id, () => []).insert(0, entry);
    notifyListeners();
    return true;
  }

  String profileName = '';
  String profileGender = 'Prefer not to say';
  bool get hasProfile => profileName.isNotEmpty;
  void setProfile(String name, String gender) {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.runes.length > 40) return;
    profileName = cleaned;
    profileGender = gender;
    you.name = cleaned;
    you.avatarInitial = String.fromCharCode(cleaned.runes.first).toUpperCase();
    _saveHistory();
    notifyListeners();
  }

  final ActivityStore? activityStore;
  Future<void> _pendingSave = Future.value();
  bool _disposed = false;
  bool historySaveFailed = false;
  Future<void> get historySaved => _pendingSave;

  static Future<AppState> load(
    ActivityStore store, {
    bool demoData = false,
    bool showcaseMode = false,
  }) async {
    final state = AppState(
      activityStore: store,
      demoData: demoData,
      showcaseMode: showcaseMode,
    );
    try {
      final stored = await store.read();
      if (stored == null) return state;
      final data = jsonDecode(stored) as Map<String, dynamic>;
      if (data['version'] != 1) throw const FormatException('Unknown history');
      state.profileName = data['profileName'] as String? ?? '';
      state.profileGender =
          data['profileGender'] as String? ?? 'Prefer not to say';
      if (state.hasProfile) {
        state.you.name = state.profileName;
        state.you.avatarInitial = String.fromCharCode(
          state.profileName.runes.first,
        ).toUpperCase();
      }
      state.audio.enabled = data['soundEnabled'] as bool? ?? showcaseMode;
      state.showCompletedQuests = data['showCompletedQuests'] as bool? ?? true;
      state.completedActivities.addAll(
        (data['activities'] as List).map(
          (entry) => CompletedActivity.fromJson(entry as Map<String, dynamic>),
        ),
      );
      for (final name in (data['interests'] as List? ?? [])) {
        final category = Category.values
            .where((c) => c.name == name)
            .firstOrNull;
        if (category != null) state.interests.add(category);
      }
      for (final entry in state.completedActivities) {
        final q = state.quests.where((q) => q.id == entry.questId).firstOrNull;
        if (q == null) continue;
        q.isCompleted = true;
        q.completionCount++;
        q.earnedXP += entry.xp;
        q.attemptNumber = max(q.attemptNumber, entry.attempt);
      }
      state.completedThisSession = state.completedActivities.length;
      state.totalXP += state.completedActivities.fold<int>(
        0,
        (sum, e) => sum + e.xp,
      );
      state.you.xp = (state.demoData ? 1075 : 0) + state.earnedXP;
      state.you.questsCompleted += state.completedActivities.length;
      for (final entry in questParents.entries) {
        if (entry.value.every((id) => state.quest(id).isCompleted)) {
          state.quest(entry.key).isLocked = false;
        }
      }
      for (final c in state.connections) {
        if (c.requiredQuestIds.every((id) => state.quest(id).isCompleted)) {
          c.isDiscovered = true;
        }
      }
      state.recentActivity.addAll(
        state.completedActivities.map(
          (e) => 'You completed ${e.title} · +${e.xp} XP',
        ),
      );
      return state;
    } catch (_) {
      state.dispose();
      rethrow; // Keep unreadable storage intact instead of replacing it.
    }
  }

  void _saveHistory() {
    final store = activityStore;
    if (store == null) return;
    final snapshot = jsonEncode({
      'version': 1,
      'soundEnabled': audio.enabled,
      'activities': completedActivities.map((e) => e.toJson()).toList(),
      'interests': interests.map((c) => c.name).toList(),
      'showCompletedQuests': showCompletedQuests,
      'profileName': profileName,
      'profileGender': profileGender,
    });
    // Serialize writes so a slower earlier completion cannot replace a newer one.
    _pendingSave = _pendingSave.then((_) async {
      try {
        await store.write(snapshot);
        historySaveFailed = false;
      } catch (_) {
        historySaveFailed = true;
      }
      if (!_disposed) notifyListeners();
    });
  }

  void retryHistorySave() => _saveHistory();
  bool showCompletedQuests = true;
  void setShowCompletedQuests(bool value) {
    showCompletedQuests = value;
    _saveHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _botTimer?.cancel();
    for (final timer in _chatTimers) {
      timer.cancel();
    }
    _chatTimers.clear();
    audio.dispose();
    for (final q in quests) {
      q.attemptClock.stop();
    }
    super.dispose();
  }

  final List<Group> groups = [];
  final Set<int> joinedGroupIds = {1};
  late final Friend player;
  int? activeGroupId = 1;
  bool get hasGroup => activeGroupId != null;
  Group get group => groups.firstWhere((g) => g.id == activeGroupId);
  List<Group> get joinedGroups =>
      groups.where((g) => joinedGroupIds.contains(g.id)).toList();
  final Map<int, List<int>> groupContributions = {};
  List<int> get challengeContributions =>
      groupContributions.putIfAbsent(activeGroupId ?? 0, () => []);

  Group createClub(String input) {
    final name = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.length < 2 || name.length > 40) {
      throw const FormatException('Choose a club name with 2–40 characters.');
    }
    final used = groups.map((g) => g.groupCode).toSet();
    if (used.length >= 9000) {
      throw const FormatException('No invite codes available.');
    }
    final random = Random.secure();
    String suffix;
    do {
      suffix = '${1000 + random.nextInt(9000)}';
    } while (used.contains('SQ-$suffix'));
    final club = Group(
      id: groups.fold<int>(0, (highest, g) => max(highest, g.id)) + 1,
      name: name,
      members: [you],
      groupCode: 'SQ-$suffix',
      inviteCode: 'INV-$suffix',
      weeklyChallengeProgress: 0,
      hostId: you.id,
    );
    _fillDemoFriends(club);
    _generatePartyTasks(club);
    groups.add(club);
    joinedGroupIds.add(club.id);
    activeGroupId = club.id;
    if (demoBotsRunning) simulateFriendCompletion();
    notifyListeners();
    return club;
  }

  JoinGroupResult joinGroup(String input) {
    final code = input.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^(SQ|INV)[0-9]{4}$').hasMatch(code)) {
      return JoinGroupResult.invalidCode;
    }
    final found = groups
        .where(
          (g) =>
              g.groupCode.replaceAll('-', '') == code ||
              g.inviteCode.replaceAll('-', '') == code,
        )
        .firstOrNull;
    if (found == null) return JoinGroupResult.unknownCode;
    if (activeGroupId == found.id) return JoinGroupResult.alreadyActive;
    if (!found.members.any((f) => f.id == 0)) found.members.add(you);
    _fillDemoFriends(found);
    if (found.partyTasks.isEmpty) _generatePartyTasks(found);
    joinedGroupIds.add(found.id);
    activeGroupId = found.id;
    notifyListeners();
    return JoinGroupResult.joined;
  }

  bool leaveGroup({int? groupId}) {
    final id = groupId ?? activeGroupId;
    if (id == null || !joinedGroupIds.contains(id)) return false;
    final leaving = groups.firstWhere((g) => g.id == id);
    _partyAttempts.removeWhere((_, attempt) => attempt.groupId == leaving.id);
    leaving.members.removeWhere((f) => f.id == 0);
    joinedGroupIds.remove(leaving.id);
    if (activeGroupId == leaving.id) activeGroupId = joinedGroupIds.firstOrNull;
    notifyListeners();
    return true;
  }

  void selectGroup(int id) {
    if (!joinedGroupIds.contains(id) || id == activeGroupId) return;
    activeGroupId = id;
    notifyListeners();
  }

  final quests = sampleQuests();
  final connections = sampleConnections();
  final Set<Category> interests = {};
  int totalXP = 0;
  int featuredId = 26;
  int? highlightedId;
  int completedThisSession = 0;
  final List<String> recentActivity = [];
  final List<CompletedActivity> completedActivities = [];

  final Random _recommendationRandom;
  Set<int> _lastSuggestions = {};

  List<Quest> suggestedNextTasks(Quest completed) {
    final candidates =
        quests
            .where((q) => q.id != completed.id && !q.isLocked && !q.isActive)
            .toList()
          ..shuffle(_recommendationRandom);
    final choices = candidates.take(3).toList();
    final selectedIds = choices.map((q) => q.id).toSet();
    if (candidates.length > 3 && setEquals(selectedIds, _lastSuggestions)) {
      choices[2] = candidates.firstWhere((q) => !selectedIds.contains(q.id));
    }
    choices.shuffle(_recommendationRandom);
    _lastSuggestions = choices.map((q) => q.id).toSet();
    return choices;
  }

  final Map<int, PartyAttempt> _partyAttempts = {};

  void _generatePartyTasks(Group party) {
    final candidates = quests.where((q) => !q.isLocked && !q.isActive).toList()
      ..shuffle();
    final selected = candidates.take(3).toList();
    final oldIds = party.partyTasks.map((t) => t.questId).toSet();
    if (candidates.length > 3 &&
        setEquals(selected.map((q) => q.id).toSet(), oldIds)) {
      selected[2] = candidates.firstWhere((q) => !oldIds.contains(q.id));
    }
    party.partyTasks
      ..clear()
      ..addAll(selected.map((q) => PartyTask(questId: q.id)));
    party.partyRound++;
  }

  bool generatePartyTasks() {
    if (!hasGroup || !group.partyComplete) return false;
    _generatePartyTasks(group);
    notifyListeners();
    return true;
  }

  bool startPartyTask(int questId) {
    if (!hasGroup) return false;
    final task = group.partyTasks
        .where((t) => t.questId == questId && !t.isCompleted)
        .firstOrNull;
    if (task == null) return false;
    final q = quest(questId);
    if (!canStart(q)) return false;
    if (q.isActive &&
        _partyAttempts[q.id]?.groupId == group.id &&
        _partyAttempts[q.id]?.round == group.partyRound &&
        _partyAttempts[q.id]?.attempt == q.attemptNumber) {
      return true; // Viewing an existing party attempt never resumes its timer.
    }
    // Evidence from an already active solo/other-party attempt cannot be reused.
    if (!q.isActive ||
        _partyAttempts[q.id]?.groupId != group.id ||
        _partyAttempts[q.id]?.round != group.partyRound ||
        _partyAttempts[q.id]?.questId != q.id ||
        _partyAttempts[q.id]?.attempt != q.attemptNumber) {
      q.isActive = false;
      q.verification.reset();
    }
    if (!start(q)) return false;
    _partyAttempts[q.id] = PartyAttempt(
      group.id,
      group.partyRound,
      q.id,
      q.attemptNumber,
    );
    notifyListeners();
    return true;
  }

  final initialGroup = Group(
    id: 1,
    name: 'Weekend Warriors',
    members: [
      Friend(
        id: 1,
        name: 'Alex',
        xp: 1250,
        avatarInitial: 'A',
        questsCompleted: 2,
      ),
      Friend(
        id: 0,
        name: 'You',
        xp: 1075,
        avatarInitial: 'Y',
        questsCompleted: 2,
      ),
      Friend(
        id: 2,
        name: 'Jordan',
        xp: 1100,
        avatarInitial: 'J',
        questsCompleted: 1,
      ),
      Friend(
        id: 3,
        name: 'Sam',
        xp: 725,
        avatarInitial: 'S',
        questsCompleted: 1,
      ),
      Friend(
        id: 4,
        name: 'Chris',
        xp: 600,
        avatarInitial: 'C',
        questsCompleted: 1,
      ),
    ],
  );
  int get level => totalXP ~/ 1000 + 1;
  int get levelXP => totalXP % 1000;
  int get earnedXP => totalXP - (demoData ? 3780 : 0);
  // Historical demo totals are separate from playable quest prerequisites.
  int get completedCount => (demoData ? 12 : 0) + completedThisSession;
  int get connectionCount =>
      (demoData ? 6 : 0) + connections.where((c) => c.isDiscovered).length;
  Friend get you => player;
  List<Friend> get leaderboard => hasGroup
      ? ([...group.members]..sort((a, b) => b.xp.compareTo(a.xp)))
      : [];
  int get rank => hasGroup ? leaderboard.indexWhere((f) => f.id == 0) + 1 : 0;
  Quest quest(int id) => quests.firstWhere((q) => q.id == id);
  Quest get featured => quest(featuredId);
  List<Quest> get activeQuests => quests.where((q) => q.isActive).toList();
  Quest? nextQuest(Quest current) {
    final candidates = quests
        .where((q) => !q.isLocked && !q.isActive && q.id != current.id)
        .toList();
    if (candidates.isEmpty) return null;
    return candidates[_recommendationRandom.nextInt(candidates.length)];
  }

  Quest? get active =>
      activeQuests.where((q) => q.attemptClock.isRunning).firstOrNull ??
      activeQuests.firstOrNull;
  double get treeProgress =>
      quests.where((q) => q.isCompleted).length / quests.length;
  int categoryCount(Category category) => quests
      .where((q) => q.categories.contains(category))
      .fold(0, (sum, q) => sum + q.completionCount);

  void buildPath(Set<Category> selected) {
    interests.addAll(selected);
    featuredId =
        selected.contains(Category.nature) &&
            selected.contains(Category.creativity)
        ? 26
        : quests
              .firstWhere(
                (q) => !q.isLocked && q.categories.any(selected.contains),
              )
              .id;
    _saveHistory();
    notifyListeners();
  }

  void newQuest() {
    final available = quests
        .where((q) => !q.isLocked && !q.isActive && q.id != featuredId)
        .toList();
    final personalized = available
        .where((q) => q.categories.any(interests.contains))
        .toList();
    final pool = personalized.isNotEmpty ? personalized : available;
    if (pool.isNotEmpty) featuredId = pool[Random().nextInt(pool.length)].id;
    notifyListeners();
  }

  bool start(Quest q) {
    if (!canStart(q)) return false;
    for (final other in quests.where((other) => other.id != q.id)) {
      other.attemptClock.stop();
      pauseRoute(other, notify: false);
    }
    if (q.isActive) {
      q.attemptClock.start();
      notifyListeners();
      return true;
    }
    _partyAttempts.remove(q.id);
    q.attemptNumber++;
    q.verification.reset();
    q.attemptClock
      ..reset()
      ..start();
    q.isActive = true;
    q.isNew = false;
    notifyListeners();
    return true;
  }

  static const maxActiveQuests = 2;
  bool canStart(Quest q) =>
      !q.isLocked && (q.isActive || activeQuests.length < maxActiveQuests);

  bool stop(Quest q) {
    if (!q.isActive) return false;
    q.isActive = false;
    q.attemptNumber++; // Ignore late GPS or photo results from this attempt.
    q.attemptClock
      ..stop()
      ..reset();
    q.verification.reset();
    _partyAttempts.remove(q.id);
    notifyListeners();
    return true;
  }

  void pauseTask(Quest q) {
    if (!q.isActive) return;
    q.attemptClock.stop();
    pauseRoute(q, notify: false);
    notifyListeners();
  }

  void toggleTaskTimer(Quest q) {
    if (!q.isActive) return;
    q.attemptClock.isRunning ? q.attemptClock.stop() : q.attemptClock.start();
    notifyListeners();
  }

  bool saveLocation(
    Quest q,
    LocationCheckIn reading, {
    required bool start,
    int? attempt,
  }) {
    if (!q.isActive ||
        (attempt != null && attempt != q.attemptNumber) ||
        q.verification.method != VerificationMethod.location ||
        !reading.isUsable) {
      return false;
    }
    final v = q.verification;
    if (start) {
      v.startLocation = reading;
      v.finishLocation = null;
    } else {
      if (v.startLocation == null ||
          !reading.recordedAt.isAfter(v.startLocation!.recordedAt)) {
        return false;
      }
      v.finishLocation = reading;
    }
    v.locationError = null;
    notifyListeners();
    return true;
  }

  void failLocation(Quest q, String message, {required int attempt}) {
    if (!q.isActive || attempt != q.attemptNumber) return;
    q.verification.locationError = message;
    notifyListeners();
  }

  void resetLocation(Quest q) {
    if (!q.isActive) return;
    q.verification.resetLocations();
    notifyListeners();
  }

  bool beginRoute(Quest q, LocationCheckIn reading, {required int attempt}) {
    if (!q.isActive ||
        q.attemptNumber != attempt ||
        !q.verification.tracksRoute ||
        !reading.isUsable ||
        reading.accuracy > 25) {
      return false;
    }
    final v = q.verification;
    v.startLocation ??= reading;
    v.finishLocation = null;
    v.locationError = null;
    v.routeFinished = false;
    v.routeTracking = true;
    v.routeAnchor = reading;
    v.lastRouteReading = reading;
    v.routeSignalMessage = null;
    notifyListeners();
    return true;
  }

  bool recordRoute(Quest q, LocationCheckIn reading, {required int attempt}) {
    if (!q.isActive ||
        q.attemptNumber != attempt ||
        !q.verification.routeTracking) {
      return false;
    }
    final accepted = q.verification.addRouteReading(reading);
    notifyListeners();
    return accepted;
  }

  void pauseRoute(Quest q, {bool notify = true}) {
    q.verification.routeTracking = false;
    q.verification.routeAnchor = null;
    q.verification.lastRouteReading = null;
    if (notify) notifyListeners();
  }

  bool finishRoute(Quest q, LocationCheckIn reading, {required int attempt}) {
    if (!q.isActive ||
        q.attemptNumber != attempt ||
        !q.verification.tracksRoute ||
        !reading.isUsable ||
        reading.accuracy > 25 ||
        q.verification.startLocation == null ||
        !reading.recordedAt.isAfter(q.verification.startLocation!.recordedAt) ||
        (q.verification.lastRouteReading != null &&
            reading.recordedAt.isBefore(
              q.verification.lastRouteReading!.recordedAt,
            ))) {
      return false;
    }
    if (q.verification.routeTracking) recordRoute(q, reading, attempt: attempt);
    q.verification.finishLocation = reading;
    q.verification.routeFinished = true;
    q.verification.locationError = null;
    pauseRoute(q);
    return true;
  }

  void setPhoto(Quest q, Uint8List? bytes) {
    if (!q.isActive) return;
    q.verification.photo = bytes;
    q.verification.photoRevision++;
    q.verification.photoReviewStatus = PhotoReviewStatus.unchecked;
    q.verification.photoReviewMessage = null;
    q.verification.demoVerified = false;
    q.verification.honorConfirmed = false;
    notifyListeners();
  }

  Future<void> reviewPhoto(Quest q) async {
    final v = q.verification;
    if (_disposed ||
        !q.isActive ||
        v.method != VerificationMethod.photo ||
        v.photo == null ||
        v.photoReviewStatus == PhotoReviewStatus.checking) {
      return;
    }
    final attempt = q.attemptNumber, revision = v.photoRevision;
    v.photoReviewStatus = PhotoReviewStatus.checking;
    v.photoReviewMessage = null;
    v.demoVerified = false;
    notifyListeners();
    bool current() =>
        !_disposed &&
        q.isActive &&
        q.attemptNumber == attempt &&
        v.photoRevision == revision;
    try {
      final review = await photoVerifier
          .review(
            title: q.title,
            description: q.description,
            evidencePrompt: v.prompt,
            image: v.photo!,
          )
          .timeout(const Duration(seconds: 30));
      if (!current()) return;
      v.photoReviewStatus = review.matches
          ? PhotoReviewStatus.approved
          : PhotoReviewStatus.rejected;
      v.photoReviewMessage = review.matches
          ? 'Photo matches this quest.'
          : '${review.reason} Choose a new photo and try again.';
    } on PhotoReviewException catch (e) {
      if (!current()) return;
      v.photoReviewStatus = PhotoReviewStatus.error;
      v.photoReviewMessage = e.message;
    } on TimeoutException {
      if (!current()) return;
      v.photoReviewStatus = PhotoReviewStatus.error;
      v.photoReviewMessage = 'Photo check timed out. Try again when connected.';
    } catch (_) {
      if (!current()) return;
      v.photoReviewStatus = PhotoReviewStatus.error;
      v.photoReviewMessage = 'Could not check this photo. Please try again.';
    }
    if (current()) notifyListeners();
  }

  void setReflection(Quest q, String text) {
    if (!q.isActive) return;
    q.verification.reflection = text;
    notifyListeners();
  }

  void setStep(Quest q, int index, bool checked) {
    if (!q.isActive || index < 0 || index >= q.verification.steps.length) {
      return;
    }
    if (checked) {
      q.verification.checkedSteps.add(index);
    } else {
      q.verification.checkedSteps.remove(index);
    }
    notifyListeners();
  }

  void confirmHonor(Quest q, bool confirmed) {
    if (!q.isActive ||
        q.verification.method == VerificationMethod.location ||
        q.verification.method == VerificationMethod.photo) {
      return;
    }
    q.verification.honorConfirmed = confirmed;
    notifyListeners();
  }

  CompletionResult? complete(Quest q) {
    // This guard makes XP awards idempotent, even if a button is tapped twice.
    if (!q.isActive || q.isLocked || !q.verification.isSatisfied) {
      return null;
    }
    final partyAttempt = _partyAttempts.remove(q.id);
    audio.play('complete');
    final oldXP = totalXP;
    final reward = q.rewardXP;
    q.earnedXP += reward;
    q.isCompleted = true;
    q.completionCount++;
    q.attemptClock.stop();
    q.isActive = false;
    q.isNew = false;
    totalXP += reward;
    completedThisSession++;
    you.xp = (demoData ? 1075 : 0) + earnedXP;
    you.questsCompleted++;
    highlightedId = q.id;
    final unlocked = <Quest>[];
    for (final entry in questParents.entries) {
      final child = quest(entry.key);
      if (child.isLocked && entry.value.every((id) => quest(id).isCompleted)) {
        child.isLocked = false;
        child.isNew = true;
        unlocked.add(child);
      }
    }
    final discovered = <Connection>[];
    for (final connection in connections) {
      if (!connection.isDiscovered &&
          connection.requiredQuestIds.every((id) => quest(id).isCompleted)) {
        connection.isDiscovered = true;
        discovered.add(connection);
      }
    }
    final partyOwner =
        partyAttempt != null &&
            partyAttempt.questId == q.id &&
            partyAttempt.attempt == q.attemptNumber &&
            joinedGroupIds.contains(partyAttempt.groupId)
        ? groups.firstWhere((g) => g.id == partyAttempt.groupId)
        : null;
    final contributionGroup = partyOwner ?? (hasGroup ? group : null);
    // A category is less explored when it has fewer than three demo completions.
    if (contributionGroup != null &&
        contributionGroup.weeklyChallengeProgress <
            contributionGroup.weeklyChallengeGoal &&
        q.categories.any((c) => categoryCount(c) <= 3)) {
      contributionGroup.weeklyChallengeProgress++;
      groupContributions.putIfAbsent(contributionGroup.id, () => []).add(q.id);
    }
    completedActivities.insert(
      0,
      CompletedActivity(
        questId: q.id,
        title: q.title,
        xp: reward,
        attempt: q.attemptNumber,
        completedAt: DateTime.now(),
        verificationMethod: q.verification.recordedMethod,
      ),
    );
    ClubCompletion? clubCompletion;
    if (partyAttempt != null &&
        partyAttempt.questId == q.id &&
        partyAttempt.attempt == q.attemptNumber &&
        joinedGroupIds.contains(partyAttempt.groupId)) {
      final party = groups.firstWhere((g) => g.id == partyAttempt.groupId);
      if (party.partyRound == partyAttempt.round) {
        final task = party.partyTasks
            .where((t) => t.questId == q.id && !t.isCompleted)
            .firstOrNull;
        if (task != null) {
          task.completedById = you.id;
          task.completedByName = you.name;
          task.completedAt = DateTime.now();
          task.earnedXP = reward;
          clubCompletion = ClubCompletion(
            groupId: party.id,
            round: party.partyRound,
            name: party.name,
            taskIds: List.unmodifiable(party.partyTasks.map((t) => t.questId)),
            completedIds: List.unmodifiable(
              party.partyTasks
                  .where((t) => t.isCompleted)
                  .map((t) => t.questId),
            ),
          );
        }
      }
    }
    final personalEntry = 'You completed ${q.title} · +$reward XP';
    recentActivity.insert(0, personalEntry);
    if (contributionGroup != null) {
      _demoClubActivity
          .putIfAbsent(contributionGroup.id, () => [])
          .insert(0, personalEntry);
    }
    _saveHistory();
    notifyListeners();
    return CompletionResult(
      q,
      oldXP,
      totalXP,
      unlocked,
      discovered,
      club: clubCompletion,
    );
  }

  List<ActivityNode> get nodes => quests
      .map(
        (q) => ActivityNode(
          questId: q.id,
          parentQuestIds: questParents[q.id] ?? [],
          childQuestIds: questParents.entries
              .where((e) => e.value.contains(q.id))
              .map((e) => e.key)
              .toList(),
          categories: q.categories,
          state: q.isCompleted
              ? NodeState.completed
              : q.isLocked
              ? NodeState.locked
              : q.isNew
              ? NodeState.newlyUnlocked
              : NodeState.available,
        ),
      )
      .toList();
  List<bool> get achievements => [
    connections.any((c) => c.isDiscovered),
    categoryCount(Category.exploration) >= 5,
    categoryCount(Category.creativity) >= 5,
    completedCount >= 10,
    rank == 1,
    quests.where((q) => questParents.containsKey(q.id) && !q.isLocked).length >=
        10,
  ];
}
