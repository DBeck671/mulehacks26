import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../app_state.dart' show JoinGroupResult;
import '../models/group.dart';
import '../models/friend.dart';
import '../models/party_task.dart';

/// Directory metadata is shared; invite secrets, requests and rosters have
/// separate rules. No admin credential or Gemini key is used by this client.
class ClubService extends ChangeNotifier {
  ClubService(this.db, this.uid);
  final FirebaseFirestore db;
  final String uid;
  final List<Group> clubs = [];
  final Set<int> joinedIds = {};
  bool loading = true;
  int? lastJoinedId;
  bool _disposed = false;
  String? error;
  final Map<String, int> _ids = {};
  final Set<String> _watchedRequests = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Map<String, List<StreamSubscription<dynamic>>> _clubSubscriptions = {};
  int _id(String id) => _ids.putIfAbsent(id, () => _ids.length + 1000);
  CollectionReference<Map<String, dynamic>> get directory =>
      db.collection('clubs');
  void start() {
    _subscriptions.add(
      directory.limit(100).snapshots().listen((snapshot) {
        final old = {for (final club in clubs) club.cloudId: club};
        clubs.clear();
        joinedIds.clear();
        for (final doc in snapshot.docs) {
          final d = doc.data();
          final memberIds = List<String>.from(d['memberIds'] as List);
          final joined = memberIds.contains(uid);
          final club = Group(
            id: _id(doc.id),
            cloudId: doc.id,
            name: d['name'] as String,
            visibility: d['visibility'] == 'public'
                ? ClubVisibility.public
                : ClubVisibility.private,
            hostUid: d['hostUid'] as String,
            hostId: d['hostUid'] == uid ? 0 : _id('member/${d["hostUid"]}'),
            members: joined ? old[doc.id]?.members ?? [] : [],
            groupCode: old[doc.id]?.groupCode ?? '',
            inviteCode: old[doc.id]?.inviteCode ?? '',
            memberLimit: d['memberLimit'] as int,
            directoryMemberCount: memberIds.length,
            weeklyChallengeProgress: 0,
          );
          club.partyTasks.addAll(
            old[doc.id]?.partyTasks ??
                (d['questIds'] as List).map(
                  (q) => PartyTask(questId: q as int),
                ),
          );
          club.partyRound = 1;
          club.joinRequests.addAll(old[doc.id]?.joinRequests ?? []);
          clubs.add(club);
          if (!joined && _watchedRequests.add(doc.id)) {
            _subscriptions.add(
              doc.reference.collection('requests').doc(uid).snapshots().listen((
                request,
              ) {
                final current = _club(doc.id);
                if (current == null) return;
                current.joinRequests.removeWhere((r) => r.uid == uid);
                if (request.exists) {
                  current.joinRequests.add(
                    ClubJoinRequest(
                      uid,
                      request.data()!['name'] as String,
                      status: request.data()!['status'] as String,
                    ),
                  );
                }
                notifyListeners();
              }, onError: _onError),
            );
          }
          if (joined) joinedIds.add(club.id);
          if (old[doc.id]?.hostUid != club.hostUid) {
            for (final sub
                in _clubSubscriptions.remove(doc.id) ??
                    <StreamSubscription<dynamic>>[]) {
              sub.cancel();
            }
          }
          if (joined && !_clubSubscriptions.containsKey(doc.id)) {
            _watchClub(club);
          }
          if (!joined) {
            for (final sub
                in _clubSubscriptions.remove(doc.id) ??
                    <StreamSubscription<dynamic>>[]) {
              sub.cancel();
            }
          }
        }
        for (final removed in old.keys.where(
          (id) => !snapshot.docs.any((d) => d.id == id),
        )) {
          for (final sub
              in _clubSubscriptions.remove(removed) ??
                  <StreamSubscription<dynamic>>[]) {
            sub.cancel();
          }
        }
        loading = false;
        error = null;
        notifyListeners();
      }, onError: _onError),
    );
  }

  void _onError(Object e) {
    if (_disposed) return;
    loading = false;
    error = 'Shared clubs are unavailable. Check your connection or Firebase Firestore setup.';
    notifyListeners();
  }

  Group? _club(String id) =>
      _disposed ? null : clubs.where((c) => c.cloudId == id).firstOrNull;
  void _watchClub(Group club) {
    final ref = directory.doc(club.cloudId);
    final subs = <StreamSubscription<dynamic>>[];
    _clubSubscriptions[club.cloudId!] = subs;
    subs.add(
      ref.collection('members').snapshots().listen((s) {
        final current = _club(club.cloudId!);
        if (current == null) return;
        current.members
          ..clear()
          ..addAll(
            s.docs.map((doc) {
              final d = doc.data();
              final name = d['name'] as String;
              return Friend(
                id: doc.id == uid ? 0 : _id('member/${doc.id}'),
                name: name,
                avatarInitial: name.isEmpty ? '?' : name.substring(0, 1),
                xp: d['xp'] as int? ?? 0,
                questsCompleted: d['questsCompleted'] as int? ?? 0,
              );
            }),
          );
        current.hostId = current.hostUid == uid
            ? 0
            : _id('member/${current.hostUid}');
        notifyListeners();
      }, onError: _onError),
    );
    if (club.hostUid == uid) {
      subs.add(
        ref.collection('requests').snapshots().listen((s) {
          final current = _club(club.cloudId!);
          if (current == null) return;
          current.joinRequests
            ..clear()
            ..addAll(
              s.docs.map(
                (d) => ClubJoinRequest(
                  d.id,
                  d.data()['name'] as String,
                  status: d.data()['status'] as String,
                ),
              ),
            );
          notifyListeners();
        }, onError: _onError),
      );
    }
    // Secrets are readable by members only, never included in discovery.
    ref
        .collection('private')
        .doc('config')
        .get()
        .then((s) {
          final current = _club(club.cloudId!);
          if (current == null || !s.exists) return;
          current.inviteCode = s.data()!['inviteCode'] as String;
          current.groupCode = current.inviteCode;
          notifyListeners();
        })
        .catchError((Object e) {
          _onError(e);
        });
  }

  Map<String, dynamic> _profile(Friend you) => {
    'name': you.name,
    'xp': you.xp,
    'questsCompleted': you.questsCompleted,
  };
  Future<Group> create(
    String input,
    int limit,
    ClubVisibility visibility,
    Friend you,
    List<int> questIds,
  ) async {
    final name = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.length < 2 || name.length > 40) {
      throw const FormatException('Choose a club name with 2–40 characters.');
    }
    if (limit < 2 || limit > 100) {
      throw const FormatException('Choose 2–100 member slots.');
    }
    final ref = directory.doc();
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code =
        'SQ-${List.generate(12, (_) => chars[random.nextInt(chars.length)]).join()}';
    final batch = db.batch();
    batch.set(ref, {
      'name': name,
      'visibility': visibility.name,
      'hostUid': uid,
      'memberIds': [uid],
      'memberLimit': limit,
      'questIds': questIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(ref.collection('private').doc('config'), {'inviteCode': code});
    batch.set(db.collection('clubCodes').doc(code), {'clubId': ref.id});
    batch.set(ref.collection('members').doc(uid), _profile(you));
    await batch.commit().timeout(const Duration(seconds: 15));
    final created =
        _club(ref.id) ??
        Group(
          id: _id(ref.id),
          cloudId: ref.id,
          name: name,
          visibility: visibility,
          members: [you],
          hostId: 0,
          hostUid: uid,
          memberLimit: limit,
          inviteCode: code,
          groupCode: code,
          weeklyChallengeProgress: 0,
        );
    created.inviteCode = code;
    created.groupCode = code;
    if (created.partyTasks.isEmpty) {
      created.partyTasks.addAll(questIds.map((id) => PartyTask(questId: id)));
    }
    created.partyRound = 1;
    if (_club(ref.id) == null) clubs.add(created);
    joinedIds.add(created.id);
    notifyListeners();
    return created;
  }

  Future<JoinGroupResult> joinCode(String input, Friend you) async {
    final code = input.trim().toUpperCase();
    if (!RegExp(r'^SQ-[A-Z2-9]{12}$').hasMatch(code)) {
      return JoinGroupResult.invalidCode;
    }
    final index = await db.collection('clubCodes').doc(code).get();
    if (!index.exists) return JoinGroupResult.unknownCode;
    final clubId = index.data()!['clubId'] as String;
    final club = _club(clubId);
    if (club == null) {
      throw const FormatException('Club is not loaded yet. Please retry.');
    }
    return join(club, you, code: code);
  }

  Future<JoinGroupResult> join(Group club, Friend you, {String? code}) async {
    lastJoinedId = club.id;
    final ref = directory.doc(club.cloudId);
    if (club.visibility == ClubVisibility.private && code == null) {
      await ref.collection('requests').doc(uid).set({
        'name': you.name,
        'status': 'pending',
        'code': '',
      });
      return JoinGroupResult.requested;
    }
    final result = await db
        .runTransaction((tx) async {
          final doc = await tx.get(ref);
          final data = doc.data()!;
          final members = List<String>.from(data['memberIds'] as List);
          if (members.contains(uid)) return JoinGroupResult.alreadyActive;
          if (members.length >= data['memberLimit']) {
            return JoinGroupResult.full;
          }
          if (code != null) {
            tx.set(ref.collection('requests').doc(uid), {
              'name': you.name,
              'status': 'pending',
              'code': code,
            });
          }
          tx.update(ref, {
            'memberIds': [...members, uid],
            if (members.isEmpty) 'hostUid': uid,
          });
          tx.set(ref.collection('members').doc(uid), _profile(you));
          return JoinGroupResult.joined;
        })
        .timeout(const Duration(seconds: 15));
    if (result == JoinGroupResult.joined) {
      final current = _club(club.cloudId!) ?? club;
      if (!joinedIds.contains(club.id)) {
        current.directoryMemberCount = current.memberCount + 1;
        joinedIds.add(club.id);
      }
      if (!current.members.any((f) => f.id == 0)) current.members.add(you);
      notifyListeners();
    }
    return result;
  }

  Future<void> review(Group club, ClubJoinRequest request, bool approve) async {
    final ref = directory.doc(club.cloudId);
    if (club.hostUid != uid) {
      throw const FormatException('Only the host can review requests.');
    }
    await db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final pending = await tx.get(ref.collection('requests').doc(request.uid));
      if (!pending.exists || pending.data()!['status'] != 'pending') {
        throw const FormatException('This request has already been reviewed.');
      }
      final members = List<String>.from(doc.data()!['memberIds'] as List);
      if (approve && !members.contains(request.uid)) {
        if (members.length >= doc.data()!['memberLimit']) {
          throw const FormatException('This club is full.');
        }
        tx.update(ref, {
          'memberIds': [...members, request.uid],
        });
        tx.set(ref.collection('members').doc(request.uid), {
          'name': request.name,
          'xp': 0,
          'questsCompleted': 0,
        });
      }
      tx.update(pending.reference, {
        'status': approve ? 'approved' : 'declined',
        'code': '',
      });
    });
  }

  Future<void> leave(Group club) async {
    final ref = directory.doc(club.cloudId);
    await db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final ids = List<String>.from(doc.data()!['memberIds'] as List);
      ids.remove(uid);
      // Transfer host to the next member; an empty club stays closed until its
      // original host rejoins using the invite code.
      tx.update(ref, {
        'memberIds': ids,
        if (club.hostUid == uid && ids.isNotEmpty) 'hostUid': ids.first,
      });
      tx.delete(ref.collection('members').doc(uid));
    });
  }

  Future<void> resize(Group club, int limit) async {
    await directory.doc(club.cloudId).update({'memberLimit': limit});
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      s.cancel();
    }
    for (final subs in _clubSubscriptions.values) {
      for (final s in subs) {
        s.cancel();
      }
    }
    super.dispose();
  }
}
