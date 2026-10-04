# SideQuest presentation kit

The JPEGs and `SideQuest-demo.mp4` are generated local presentation media,
excluded from Git. The video is a motion composition of actual 440×956 browser
captures, with gentle camera movement, fades, and the app's original join and
completion sounds. It is not a recording of a native iPhone app. Simulated
friends and the simulated walk completion remain labeled in the app.

Run `render_video.py` with a Python environment containing `imageio-ffmpeg` to
rebuild the 42-second, 1080×1920, 30 fps MP4 after capturing the numbered JPEGs.
The renderer currently uses macOS's Arial font path.

For an isolated live presentation, build `lib/capture_main.dart` to
`build/capture_web` and serve it on loopback port 8085. It has no history store:
refreshing resets only this fixture. Use `lib/demo_main.dart` on port 8083 for
the existing persistent showcase history. Both are explicitly marked DEMO.
Start `server/photo_server.py` separately for live photo verification; keep
the ignored Gemini credential file outside the web build.

Validation on 2026-10-04: 91 Flutter tests, 5 gateway tests, clean Flutter
analysis, and successful authenticated, showcase, and capture release builds.
Browser checks covered quest start/pause/resume/stop, two active-task summaries,
completion animation and suggestions, history, club creation and capacity
editing, shared bot tasks/activity/chat, badge selection, and actual Gemini
rejection/approval. Firebase's configured live endpoint rejected invalid login
credentials. Successful account creation/sign-in and email delivery were not
retested with a real account in this run; auth UI and account isolation tests
use injected services. Browser console showed no captured errors in the demo.

This kit is suitable for a controlled laptop demo. Before public production
deployment: synchronize account progress/clubs/chat in an authorized cloud
store; host photo verification over HTTPS with Firebase ID-token validation,
canonical quest checks and per-user limits; configure deployed auth domains;
test outdoor GPS and native iPhone behavior. Reward coupons are sample offers,
not live partner redemptions. Do not expose the loopback gateway publicly.
