import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../services/location_service.dart';
import 'common.dart';

class LocationVerification extends StatefulWidget {
  const LocationVerification({
    super.key,
    required this.state,
    required this.quest,
  });
  final AppState state;
  final Quest quest;
  @override
  State<LocationVerification> createState() => _LocationVerificationState();
}

class _LocationVerificationState extends State<LocationVerification>
    with WidgetsBindingObserver {
  bool locating = false;
  String? message;
  StreamSubscription? routeSubscription;
  bool get foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeSubscription?.cancel();
    if (widget.quest.verification.tracksRoute) {
      widget.state.pauseRoute(widget.quest, notify: false);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && routeSubscription != null) {
      pauseTracking();
    }
  }

  void pauseTracking() {
    routeSubscription?.cancel();
    routeSubscription = null;
    widget.state.pauseRoute(widget.quest);
    if (mounted) {
      setState(
        () => message = 'Tracking paused. Resume when this task is open again; untracked movement is not counted.',
      );
    }
  }

  Future<void> startTracking() async {
    if (locating || widget.quest.verification.routeTracking) return;
    final q = widget.quest, attempt = q.attemptNumber;
    setState(() {
      locating = true;
      message = null;
    });
    try {
      final reading = await LocationService.checkIn();
      if (!mounted || q.attemptNumber != attempt || !q.isActive) return;
      if (!foreground) {
        throw const FormatException(
          'Return to this task and retry GPS tracking.',
        );
      }
      if (!widget.state.beginRoute(q, reading, attempt: attempt)) {
        throw FormatException(
          'GPS accuracy is ±${reading.accuracy.round()} m. Walks and runs need accuracy within 25 m. Move outdoors with precise location enabled, then retry.',
        );
      }
      routeSubscription = LocationService.watch().listen(
        (reading) {
          if (!mounted || q.attemptNumber != attempt || !q.isActive) {
            routeSubscription?.cancel();
            routeSubscription = null;
            return;
          }
          widget.state.recordRoute(q, reading, attempt: attempt);
        },
        onError: (Object error) {
          if (!mounted || q.attemptNumber != attempt) return;
          routeSubscription?.cancel();
          routeSubscription = null;
          widget.state.pauseRoute(q);
          widget.state.failLocation(
            q,
            error is FormatException
                ? error.message
                : 'GPS stopped. Check location permissions and retry.',
            attempt: attempt,
          );
        },
        onDone: () {
          if (mounted && q.verification.routeTracking) pauseTracking();
        },
      );
    } catch (error) {
      if (mounted && q.attemptNumber == attempt) {
        widget.state.pauseRoute(q);
        widget.state.failLocation(
          q,
          error is FormatException ? error.message : 'GPS is unavailable. Allow location access for this app and retry.',
          attempt: attempt,
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> finishTracking() async {
    if (locating) return;
    final q = widget.quest, attempt = q.attemptNumber;
    setState(() {
      locating = true;
      message = null;
    });
    // Cancellation stops delivery immediately; a platform cleanup future must
    // not block acquiring the finish fix or leave the progress button spinning.
    routeSubscription?.cancel();
    routeSubscription = null;
    try {
      final reading = await LocationService.checkIn();
      if (!mounted || q.attemptNumber != attempt || !q.isActive) return;
      if (!foreground) {
        throw const FormatException(
          'Return to this task and retry the finish check.',
        );
      }
      if (!widget.state.finishRoute(q, reading, attempt: attempt)) {
        throw const FormatException(
          'Finish location is not reliable. Resume tracking and try again outdoors.',
        );
      }
    } catch (error) {
      if (mounted && q.attemptNumber == attempt) {
        widget.state.pauseRoute(q);
        widget.state.failLocation(
          q,
          error is FormatException
              ? error.message
              : 'Could not get a fresh finish location. Retry GPS tracking.',
          attempt: attempt,
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Widget routeControls() {
    final q = widget.quest, v = q.verification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          v.routeTracking
              ? 'GPS TRACKING LIVE'
              : v.locationVerified
              ? 'VERIFICATION PASSED'
              : 'GPS TRACKING ${v.startLocation == null ? 'READY' : 'PAUSED'}',
          style: const TextStyle(
            color: green,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${v.verifiedDistance.floor()} / ${v.minimumDistance.round()} m verified route',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SmoothBar(value: v.verifiedDistance / v.minimumDistance),
        if (v.lastRouteReading != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'GPS accuracy: ±${v.lastRouteReading!.accuracy.round()} m',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ),
        if (v.routeSignalMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              v.routeSignalMessage!,
              style: const TextStyle(color: muted, height: 1.5),
            ),
          ),
        if (v.locationFailed)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Semantics(
              liveRegion: true,
              child: Text(
                v.locationError ??
                    'DISTANCE NOT MET — VERIFICATION FAILED\nTrack ${(v.minimumDistance - v.verifiedDistance).ceil()} m more, then finish again.',
                style: const TextStyle(
                  color: Colors.redAccent,
                  height: 1.6,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (q.isActive) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (v.routeTracking) ...[
                FilledButton.icon(
                  onPressed: locating ? null : finishTracking,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('FINISH TRACKING'),
                ),
                TextButton(
                  onPressed: locating ? null : pauseTracking,
                  child: const Text('PAUSE'),
                ),
              ] else if (!v.locationVerified)
                OutlinedButton.icon(
                  onPressed: locating ? null : startTracking,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    v.locationFailed
                        ? 'RETRY VERIFICATION'
                        : v.startLocation == null
                        ? 'START GPS TRACKING'
                        : 'RESUME GPS TRACKING',
                  ),
                ),
              if (v.startLocation != null)
                TextButton(
                  onPressed: locating
                      ? null
                      : () {
                          pauseTracking();
                          widget.state.resetLocation(q);
                          setState(() => message = null);
                        },
                  child: const Text('Reset tracking'),
                ),
            ],
          ),
        ],
        if (locating)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              message!,
              style: const TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Keep this task open. Tracking pauses when you leave; movement while paused does not count.',
          style: TextStyle(color: muted, fontSize: 11, height: 1.5),
        ),
      ],
    );
  }

  Future<void> checkIn(bool start) async {
    final attempt = widget.quest.attemptNumber;
    setState(() {
      locating = true;
      message = null;
    });
    try {
      final reading = await LocationService.checkIn();
      if (!mounted || attempt != widget.quest.attemptNumber) return;
      final saved = widget.state.saveLocation(
        widget.quest,
        reading,
        start: start,
        attempt: attempt,
      );
      if (!saved) {
        widget.state.failLocation(
          widget.quest,
          'Location check failed. Capture a fresh location and retry.',
          attempt: attempt,
        );
      }
      setState(
        () => message = !saved
            ? 'This quest changed or the location is out of date. Try again.'
            : start
            ? 'Starting location saved. Enjoy your activity, then check in again.'
            : widget.quest.verification.locationVerified
            ? 'Movement verified! You can complete your SideQuest.'
            : 'Not far enough from your start yet. Keep exploring, then retry the finish check-in.',
      );
    } on FormatException catch (error) {
      if (mounted && attempt == widget.quest.attemptNumber) {
        widget.state.failLocation(
          widget.quest,
          error.message,
          attempt: attempt,
        );
        setState(() => message = error.message);
      }
    } catch (_) {
      if (mounted && attempt == widget.quest.attemptNumber) {
        widget.state.failLocation(
          widget.quest,
          'Location is unavailable. Check permissions and retry.',
          attempt: attempt,
        );
        setState(
          () => message = 'Location is unavailable. Check device or browser permissions, then retry.',
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quest, v = q.verification;
    if (v.tracksRoute) return routeControls();
    final editable = q.isActive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(
              v.startLocation == null
                  ? Icons.radio_button_unchecked
                  : Icons.check_circle_outline,
              color: v.startLocation == null ? muted : green,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                v.startLocation == null
                    ? 'Starting location not saved'
                    : 'Starting location saved',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        if (v.finishLocation != null) ...[
          const SizedBox(height: 12),
          Text(
            '${v.verifiedDistance.floor()} / ${v.minimumDistance.round()} m verified displacement',
            style: TextStyle(
              color: v.locationVerified ? green : muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          SmoothBar(value: v.verifiedDistance / v.minimumDistance),
          const SizedBox(height: 8),
          Text(
            'Straight-line distance: ${v.displacement.floor()} m. Accuracy margin deducted.',
            style: const TextStyle(color: muted, fontSize: 10, height: 1.5),
          ),
        ],
        if (v.locationFailed) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(
              v.locationError == null
                  ? 'DISTANCE NOT MET — VERIFICATION FAILED\nMove at least ${(v.minimumDistance - v.verifiedDistance).ceil()} m farther from your start, then retry.'
                  : 'LOCATION CHECK FAILED\n${v.locationError}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ] else if (v.locationVerified) ...[
          const SizedBox(height: 14),
          const Text(
            'VERIFICATION PASSED',
            style: TextStyle(color: green, fontWeight: FontWeight.w700),
          ),
        ],
        if (editable) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (v.locationFailed)
                OutlinedButton.icon(
                  onPressed: locating
                      ? null
                      : () => checkIn(v.startLocation == null),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('RETRY VERIFICATION'),
                )
              else if (v.startLocation == null)
                OutlinedButton.icon(
                  onPressed: locating ? null : () => checkIn(true),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Save start location'),
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: locating ? null : () => checkIn(false),
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: Text(
                    v.finishLocation == null
                        ? 'Check finish location'
                        : 'Retry finish check-in',
                  ),
                ),
              ],
              if (v.startLocation != null)
                TextButton(
                  onPressed: locating
                      ? null
                      : () {
                          widget.state.resetLocation(q);
                          setState(() => message = null);
                        },
                  child: const Text('Reset check-ins'),
                ),
            ],
          ),
          if (locating)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  message!,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Location is read only when you tap a check-in. Two points stay local for this session; no route or background tracking. This verifies displacement, not walking time or transport method.',
          style: TextStyle(color: muted, fontSize: 11, height: 1.5),
        ),
      ],
    );
  }
}
