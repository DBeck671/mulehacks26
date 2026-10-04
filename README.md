# SideQuest

**Every experience leads somewhere.** A local Flutter hackathon prototype about connecting real-world activities and friends through shared adventures.

## Run

With Flutter installed:

```sh
flutter pub get
flutter run
```

Choose an Android emulator, iOS simulator (requires Xcode), or attached phone. For a browser demo:

```sh
flutter run -d chrome
```

Firebase Authentication is required for login and account creation. See the setup section below. Completed activity history, repeat counts, earned XP and quest display preferences are saved locally per Firebase account. Signing out closes protected routes but keeps the saved log. Clubs and active verification attempts still live in memory; history is not yet synchronized between devices.

## Live demo

1. Start exploring and select Nature + Creativity.
2. Start the featured **Nature Through a New Lens** quest, add and verify matching photo evidence, and complete it for 100 XP.
3. After the XP animation, choose one of three different suggested tasks or **Return to Home**. The task just completed is excluded.
4. Continue as long as you like. Repeat attempts need fresh verification. The first completion earns full XP; every later completion earns half the base reward (rounded down, minimum 1 XP).
5. Open **Activity Log** to see completed tasks grouped into one card per task. Each card shows the completion count, total earned XP, latest completion time, and latest verification method. Cards are ordered by most recent completion; individual attempt records remain intact.
6. Open Friends and Progress to see shared XP and achievements.

The demo starts at level 4, with 780/1000 level XP (3,780 lifetime XP). Weekly XP starts at 1,075; every reward updates lifetime and weekly XP together. The initial 12 completions and 6 connections are historical sample totals, not prerequisite completions of the playable quests. The Activity Log starts empty and records actual successful attempts saved on this device. Historical sample totals do not create fake log entries. The weekly challenge starts at 7/10, awards 500 group XP once at 10/10, and counts completions in less-explored categories (up to three local completions per category).

## Code guide

- `lib/main.dart`: Material 3 theme and app entry.
- `lib/app_state.dart`: one shared ChangeNotifier; XP, completion guards, unlock rules, leaderboard, and achievements.
- `lib/models/`: simple Quest, ActivityNode, Connection, Friend, and Group models.
- `lib/data/sample_quests.dart`: 26 quests, parent relationships, and four cross-category connections.
- `lib/screens/`: onboarding, persistent five-tab shell, details, follow-up task choices, activity log, friends, and progress.
- `lib/widgets/common.dart`: reusable cards, category filters, XP bars, and typography.

`MainScreen` uses an `IndexedStack` to preserve tab state. Quest completion requires starting the quest first and awards XP once per successful attempt: full base XP first, then half base XP on repeats (rounded down, minimum 1). Completed quests can be started again with fresh evidence; completion counts and previously available tasks remain available. Every parent must be completed to unlock a locked quest. Multiple quests can stay in Active; starting another pauses the previous timer and GPS without discarding evidence. The Activity Log replaces the tree page. Follow-up choices are three distinct, randomly sampled available tasks, in shuffled order, excluding the task just completed. Tasks remain repeatable through Quests or the Activity Log. Consecutive combinations do not repeat when additional candidates exist. Choices stay stable while viewing a completion screen. Selecting a recommendation starts that attempt and replaces the completed details screen, avoiding an ever-growing navigation stack. Returning home leaves no task active.

An XP count-up and progress-bar animation plays first after each successful completion. Once it finishes, three task choices fade into view. Failed location checks cannot create log entries or recommendations.

## Checks

```sh
flutter analyze
flutter test
flutter build web
```

No contacts or background tracking is used. Walks and outdoor movement offer live GPS route tracking while the task is open. Place-to-place quests use start/finish location check-ins. Camera access is requested only when you choose Take photo. Group invitations support local demo codes; online joining is intentionally a future feature. AI-generated quests can use the existing Quest model later, with API calls behind a server rather than credentials embedded in Flutter.

## Quest verification

Every quest displays its verification method in the card and details:

- Photo evidence for photography, parks, sunsets, recipes, sketches, and other visual activities. Choose a local image (web and mobile), or take a photo (Android/iOS). Preview, replace, and remove are supported. Invalid images and files over 10 MB are rejected. Tap **Check photo** to send a resized PNG (with file metadata removed) to Google Gemini through Firebase AI Logic. Only an explicit matching result enables completion. Mismatched or unclear photos ask for a replacement; network, quota, blocked, malformed, and timed-out responses do not pass. Photo quests do not offer honor-based confirmation.
- Short reflections for reading, learning, and exploration. Write at least 20 characters (up to 600).
- Activity-specific checklists for stationary wellness activities. Check every step.
- Location check-ins for walks, parks, detours, morning movement, nature exploration, outdoor adventures, new places, and outdoor routes.

Completion is disabled until the assigned evidence is supplied, or, for reflection/checklist quests, the user explicitly chooses honor-based confirmation. Location quests cannot bypass distance verification. The shared state enforces this too. Evidence stays attached to its quest across navigation and can be viewed after completion; each successful repeat starts with fresh evidence, and successful completion summaries and rewards survive restart; pending evidence stays in memory. Photo checks upload only the chosen image and task text to Google when the user taps Check photo; the image is not saved to Firebase Storage or shared with the club by this app. Visual matching cannot prove identity, ownership, freshness, duration, or that the user personally did the task. GPS coordinates and other evidence are not uploaded. Native camera permissions and device photo picking require a physical-device smoke test; Android process recreation resets this in-memory prototype, including pending evidence.

## Joining demo groups

Friends includes a **Join a group** section accepting either an invite code or group code. Try `SQ-7319` or `INV-7319` to join Curiosity Club. Use `SQ-4821` or `INV-4821` for Weekend Warriors. Codes accept lowercase, optional hyphens, and spaces. Empty, malformed, unknown, and current-group codes get clear feedback. Joined groups appear as stacked clickable club cards, and Invite Friend shows and copies the invite code. Leave Group removes your membership and switches to another joined group, or shows the join section when none remain. XP and quest history remain intact.

Joining switches the active group without changing XP, quest progress, or verification evidence. Both demo crews include the same sample friends and the same player. Challenge progress and contribution counts are separate for each group. This works locally within the demo session; codes do not connect to another device or server.

## Location verification

For walks, morning movement, outdoor adventures, outdoor exploration and outdoor workouts, tap **START GPS TRACKING** after starting the quest. Allow location and keep the task open while moving. Live distance excludes weak readings (accuracy worse than 25 m), simulated locations, unrealistic jumps, noisy movement below combined accuracy margins, and GPS gaps longer than 45 seconds. Tap **FINISH TRACKING** to verify the distance. A loop can pass even if it returns to the start. A short route fails with **RETRY VERIFICATION**, which resumes the attempt and retains already verified distance. Pause/resume does not count movement while paused. Leaving the task or backgrounding the app pauses tracking. Raw coordinates remain in memory and are not uploaded or persisted in the activity log.

For parks, detours, nature exploration and new places, tap **Save start location** and then **Check finish location**. These quests check straight-line displacement using two readings accurate to within 50 m, subtracting both accuracy margins. All fixes must be fresh. Thresholds range from 100–250 m depending on the quest. None of these checks proves transport method or a park boundary.

Location-denied, disabled, timeout, and imprecise readings show guidance. Insufficient verified distance explicitly fails verification and disables completion. Every failed check offers Retry Verification. Permission and capture failures also offer retry; location quests have no honor-based bypass. Actual device positioning and permissions still need an Android/iOS smoke test. Browser geolocation requires a supported secure context (HTTPS or a trusted localhost) and permission; the in-app preview may not provide accurate movement readings. No fake coordinates are used in the application; simulated readings exist only in tests.

## Shared party task lists

Friends automatically generates three available tasks for each joined group. Tap **Do Party Task** to start a fresh attempt with the task's normal verification requirements. Successful completion checks off that shared task and records who completed it and the XP earned. Failed verification and duplicate completion taps do not advance the board. Once all three tasks are complete, **Generate Next Party List** starts a new round.

Boards and completion credit belong to the party where the attempt started, even when switching groups. Leaving that party cancels pending party credit. A solo completion does not retroactively fill a party task. Each task needs one party-member completion, rather than every member repeating it. Repeat rewards still use half base XP, minimum 1.

Party membership, task lists, and contributions currently stay in local memory. Sample friends cannot submit real cross-device completions until authentication and a shared backend are connected; the UI labels this limitation.

## Start a club and invite friends

Friends offers **Start a Club** even when you are not in a group. Choose a name (2–40 characters); you become the host of a new club with one member, a fresh party board, and a unique `INV-####` code. The invite sheet opens immediately. **Copy invite code** puts the code on the clipboard; **Share Invite** opens the platform sharing UI where supported, with a copy fallback message when unavailable. Sharing only happens when the user chooses a recipient in that UI.

Leaving preserves the club and party progress. Enter its invite code to rejoin within the current demo session. Newly created clubs start at zero weekly challenge progress. Codes and club membership do not yet synchronize across devices or survive app restarts; an online backend is required for remote friends to join and contribute.

The share action uses [share_plus](https://pub.dev/packages/share_plus). Native share sheets require a physical-device smoke test.

## Page layout

Home gives the current task and XP progress the main visual emphasis, followed by one compact weekly leaderboard. The previous Friends This Week card and Home statistics strip are removed; detailed statistics remain in Progress.

Friends focuses on clubs and members: compact Start a Club and Join a Group controls, invite/leave actions, and a member list. Joining opens a sheet instead of keeping a form on the page. **Club Activity**, below the club card, opens shared party tasks and recent updates on a separate screen. The weekly group quest is at the top of Friends. Returning home after a party task closes that activity screen too.


Quests uses full-width horizontal cards in a vertically scrolling stack. Category filters remain available. Navigation order is **Home · Quests · Progress · Friends**. Activity Log, Account, Settings and Log out live in the side menu.

## Firebase accounts

The app now starts at login. Email/password account creation, password confirmation, password reset, persistent Firebase sessions, email verification actions, and sign-out are implemented with the official Firebase Flutter SDK. Signed-out users cannot access app routes. Signing out disposes the entire protected navigator and local gameplay state, so a different account cannot inherit the previous account's quest evidence or open screens. Successful task summaries are retained separately per account on this device. The `demoMode` constructor option is an explicit widget-test harness and is never enabled by the production entry point.

Passwords go directly to Firebase Authentication over its HTTPS connection; the app does not hash, log, write passwords to disk, or put passwords in gameplay models. Firebase stores salted password hashes using its modified scrypt algorithm ([Firebase documentation](https://firebase.google.com/docs/auth/admin/import-users)). The SDK handles session tokens and refresh; Firebase Auth does not automatically persist quest data.

### Connect your project

The free Spark project `sidequest-7c7e0` is connected by default through public platform options in `lib/auth/firebase_options.dart`. Email/Password is enabled and localhost is authorized. Normal `flutter run -d chrome` and `flutter build web --pwa-strategy=none` use this project. Android and iOS app IDs are registered for `com.sidequest.sidequest`. Native device login still needs testing; iOS currently uses the project's browser client API key with explicit options because the console's plist download was unavailable. Run `flutterfire configure` before a native release to obtain the auto-matched platform config.

To use a different project:

1. Register the target platforms and enable Email/Password in Firebase Authentication.
2. Require a minimum of 15 password characters, use email enumeration protection, and authorize localhost and your deployment domain.
3. Copy `config/firebase.example.json` to `config/firebase.local.json` and fill that platform's public identifiers. Never use a service-account private key.
4. Run `flutter run -d chrome --dart-define-from-file=config/firebase.local.json`. Overrides must include all required identifiers; partial overrides disable login.

For a local design preview past login, build with `flutter build web --target=lib/preview_main.dart --output=build/preview_web --pwa-strategy=none`. This separate entry does not change the normal authenticated app. Preview history has its own local storage namespace.

Navigation: Home, Quests, Progress, Activity Log and Friends stay in the bottom bar. The header account button opens Account, Settings and Log out. The weekly group quest is at the top of Friends. Quests use stacked horizontal cards. Settings can hide completed quests without removing them from the saved activity log.

Missing or invalid configuration shows an unavailable login screen with disabled submission; there is no fake login or silently accepted account. Password creation validates 15–128 Unicode characters locally and matching confirmation; Firebase's server policy remains authoritative. Login failures use generic credential feedback and reset feedback does not reveal whether an account exists. Verification email and refresh actions are available in Side menu → Account. Email verification is displayed but is not required to use the local gameplay demo.

Real account creation, delivered verification/reset emails, Firebase rate limiting, and native session restoration require the connected project and device tests. Widget tests use an injected fake auth service to exercise validation, failure handling, account gates, route cleanup, and sign-out. Deploy the web app over HTTPS. Any future shared gameplay backend must authorize requests using verified Firebase ID tokens and account-scoped rules; local gameplay is not such a backend.

Quest attempts show a live estimated-time countdown (or elapsed time for flexible durations), with timer pause/resume. Time does not bypass evidence verification. Stop task clears the attempt and timer without XP or an Activity Log entry; earlier completions remain. Timers and unfinished attempts are session-only.

First-time account setup asks for a name/nickname, optional gender (including Prefer not to say), and at least two interests. These are saved per account on this device alongside history; interests personalize quests, gender does not. Existing accounts without profile details are prompted on their next login.

The embedded desktop browser can report Firebase network failures even when Chrome reaches the backend. Use the authenticated app in regular Chrome for live account testing. A phone-sized browser viewport does not emulate phone GPS. Web GPS requests a high-accuracy position directly with a bounded timeout rather than using the plugin's unbounded permission request.

Normal authenticated accounts start at Level 1 with zero XP, zero completed tasks/connections/achievements, no club memberships and no sample friends. Only the explicit `demoData: true` preview/test fixtures seed example progress. Saved Firebase-UID-scoped completion records restore only that account's earned XP; synthetic baseline XP is never added to real accounts. Profile and history currently persist on this device, not across devices. Clubs remain a local prototype and do not yet synchronize between real accounts.

Completing a club/party task shows XP first, then the fixed shared task list and completed count. Only unfinished tasks from the same club round can be continued; these preserve party credit. The last completion celebrates the list rather than suggesting new tasks or automatically generating a new round. Return to Club takes users back to Club Activity. Solo tasks still show randomized recommendations.

Friends prioritizes a compact weekly challenge and one active club card, with shared task progress, Club Activity and Invite actions. Members expand on demand; create/join/leave remain secondary. Common buttons, input fields and bottom sheets share restrained spacing and rounded styles. Bottom tabs fade gently while preserving scroll positions; reduced-motion settings skip the tab fade. Stop task is always reachable in an active quest's top bar.

Progress → Activity tree and locked task → View unlock path display an interactive prerequisite map. Choose any task, see all ancestors and completed/available/locked statuses, and tap a node to open its details. The map fits the screen width and scrolls vertically without pan or zoom. The iPhone 17 Pro Max design viewport is 440 × 956 logical pixels (1320 × 2868 at 3× scale); a browser viewport does not emulate native safe areas, hardware GPS or iOS permissions.


### Presentation demo

Run `flutter run -d chrome -t lib/demo_main.dart` or build with
`flutter build web -t lib/demo_main.dart -o build/demo_web --pwa-strategy=none`.
This entry skips account login and uses the separate `showcase-demo-v1` local
history key. The DEMO badge identifies the presentation version. Its existing
sample members are labelled bots. Every newly created demo club receives four
dummy friends. They contribute to the fixed shared list every 12 seconds,
including an initial contribution, and appear in that club's Recent Activity.
Club Activity includes pause/resume and a manual contribution button. Bot contributions
update the club and leaderboard, never personal XP or activity history.
Bot contributions and clubs are session-local and restart on reload.
The simulator never takes a task currently active for the user and does not
generate a new task list after completion.

Start a quest, use **Simulate verification · demo**, then complete it to show
the XP count-up, particle celebration and follow-up choices. Simulated
completions are labelled **Demo simulation** in history. Normal Firebase
accounts do not expose either simulation control. Demo history persists
independently of real users.

Bundled original WAV cues play on quest completion and club joins. Navigation,
quest start and next-task browsing are silent. Mute using the demo header speaker or Settings → Sound
effects. Normal accounts start with sound off. Playback requires an allowed
browser user gesture; audio failure never blocks gameplay. Motion respects
the system reduced-motion preference.

Quests now has **Explore** and **Active** tabs. Started quests remain available
until completed or explicitly stopped. At most two tasks can be active. Timers
continue while browsing until manually paused; opening a task does not start
or resume it. GPS pauses when leaving its screen and requires an explicit
resume/start. Active
attempts and evidence are session-local; only completed history is persisted.

Tap **Next quest** in the fixed bottom bar or swipe left to browse another
available task, including after starting a quest. Started tasks are
retained in Active with their running timer and evidence intact. Skipping replaces
the current task screen, does not start the next task or
award XP, and excludes locked/active tasks.
Club tasks already started from the shared list keep their club-specific flow.

Tap a club card on Friends to open its detail page. **Tasks**, **Members**,
and **Activity** tabs keep the shared list, member roster and team completion
log together. Members no longer expands on the Friends page. Team activity
is scoped to the selected club and remains session-local.

Friends shows all joined clubs as stacked cards. Start Club and Join Group
appear below the weekly group quest, before the list. Each card has an invite
action and its own Leave Group control; leaving an unselected club does not
change the currently selected club.

Activity tree shows all 26 quests and every prerequisite connection on a
spacious canvas with read-only nodes. Drag to explore, pinch to zoom, or use the
compact +/− controls; nodes and connections cannot be clicked. Active quests pulse and their directly attached
links glow. Brief active-task summaries appear beneath the tree. Category icons
and unlock/completion status remain visible.

Mouse-wheel, trackpad and touch gestures inside the tree move only its canvas;
the surrounding Progress page scrolls when the pointer is outside that section.
In a demo account, Account menu → Settings → Reset demo account clears XP,
completed history, active attempts, unlocks/connections, tokens, claims, badges,
clubs and chat. It also removes seeded progress so the demo stays at Level 1
after reopening. The button requires confirmation and is absent for real users.

Club hosts choose 2–100 member slots, including themselves, when creating a
club, and can adjust them from Club Activity → Members. Joining a full club
fails without changing membership. In showcase mode, dummy friends fill the
chosen capacity; normal accounts never receive simulated members.

Tree cards, category labels and branch lines use the shared category colours:
Nature green, Creativity purple, Learning blue, Exploration orange, Wellness
pink, and Food yellow. Multi-category quests show every category label; lock
and completion status remain separate from the category colour.

Completed quest cards retain their original category icons. Completion is
shown by status text rather than replacing the task icon with a tick.

## AI photo checking setup

Photo verification now uses the **direct Gemini Developer API through a server**; Firebase continues to handle accounts. No Gemini credential is embedded in Flutter. The client accepts only an explicit `match`; mismatches and unclear evidence require another photo, while missing keys, outages, quota failures and malformed responses never approve. Existing attempt/revision guards and the 30-second limit remain in place.

### Local demo photo setup

1. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/apikey).
2. Put it in `config/gemini.local.json` as `{ "apiKey": "YOUR_KEY" }`, or set the server's `GEMINI_API_KEY` environment variable. The local file is ignored by Git. Do not put the key in a Dart define or Flutter asset.
3. Run `python3 -m venv server/.venv`, then `server/.venv/bin/python -m pip install -r server/requirements.txt`, then `server/.venv/bin/python server/photo_server.py`. It listens only on `127.0.0.1:8084` and accepts the existing local previews on ports 8081 and 8083. The server rereads the key file for each request, so saving the key does not require restarting it.
4. Open a newly built preview and check a photo. `http://127.0.0.1:8084/health` reports only whether a key is present, not whether Google accepts it.

The gateway calls `gemini-3.5-flash`, overridable with the server's `GEMINI_MODEL`. Uploaded images are normalized to PNG by Flutter, size limited, sent to Google, and not saved or logged by the gateway. JSON verdicts are validated, and requests have timeouts, concurrency limits and a local rate cap.

### Public deployment

This gateway is deliberately **local demo only**. For an actual phone/public link, deploy the Flutter web build and an HTTPS backend; set `--dart-define=PHOTO_REVIEW_URL=https://YOUR_BACKEND/api/photo-review`. Before exposing the backend, add Firebase ID-token verification, server-side canonical quest lookup, per-user limits and explicit allowed origins. Store `GEMINI_API_KEY` in the hosting provider's secret store. The loopback gateway must not be publicly exposed or tunneled as-is. Firebase Authentication authorized domains also need the deployed web domain. Public deployment and native distribution are not configured by this local setup.
