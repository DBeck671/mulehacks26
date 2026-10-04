# SideQuest screenshots and development stages

34 actual browser screenshots captured October 4, 2026 at a 440 × 956 CSS-pixel phone viewport. These are Flutter web-preview captures, not native iPhone screenshots or generated mockups.

## Capture context

- Login and create-account screenshots come from the configured authentication preview at localhost:8081. No account was created and no credentials were entered.
- Other screens come from an isolated in-memory capture fixture at localhost:8085. They do not alter the user’s running demo at localhost:8083 or its saved activity history.
- The fixture starts at a seeded demo level. Real new accounts start fresh. Bot members, bot chat, sample partner offers and simulated completion are presentation data.
- GPS screenshot shows the tracking requirements and ready state; it is not evidence of a real outdoor GPS test. The photo completion uses the explicitly marked demo simulation, not a new Gemini verification request.
- Long pages have additional scroll-position screenshots. The XP celebration image deliberately captures an animation frame, while the suggestions image shows the settled result.
- The set contains current UI flow stages. The development milestones below are verified Git history, not a claim that these images show older versions.

## Screenshot index

- [01 home](01-home.jpg)
- [02 quests](02-quests.jpg)
- [03 quest detail](03-quest-detail.jpg)
- [04 active task](04-active-task.jpg)
- [05 paused task](05-paused-task.jpg)
- [06 xp celebration](06-xp-celebration.jpg)
- [07 completion suggestions](07-completion-suggestions.jpg)
- [08 progress tree](08-progress-tree.jpg)
- [09 progress paths](09-progress-paths.jpg)
- [10 activity log](10-activity-log.jpg)
- [11 friends my clubs](11-friends-my-clubs.jpg)
- [12 club discovery](12-club-discovery.jpg)
- [13 create club](13-create-club.jpg)
- [14 join code](14-join-code.jpg)
- [15 club tasks](15-club-tasks.jpg)
- [16 club members](16-club-members.jpg)
- [17 club activity](17-club-activity.jpg)
- [18 group chat](18-group-chat.jpg)
- [19 account menu](19-account-menu.jpg)
- [20 account](20-account.jpg)
- [21 settings dark](21-settings-dark.jpg)
- [22 settings light](22-settings-light.jpg)
- [23 friends light](23-friends-light.jpg)
- [24 rewards light](24-rewards-light.jpg)
- [25 badges light](25-badges-light.jpg)
- [26 welcome](26-welcome.jpg)
- [27 profile onboarding](27-profile-onboarding.jpg)
- [28 login](28-login.jpg)
- [29 create account](29-create-account.jpg)
- [30 gps verification](30-gps-verification.jpg)
- [31 active quests tab](31-active-quests-tab.jpg)
- [32 active tree connections](32-active-tree-connections.jpg)
- [33 rewards dark](33-rewards-dark.jpg)
- [34 badges dark](34-badges-dark.jpg)

## Development milestones

All milestones below were committed October 4, 2026; the repository initial commit was October 3.

### 1. Core app

Quest catalogue, verification methods, accounts, clubs and saved history.

Source: commit `f038a64` — Build SideQuest app with verified quests, accounts, clubs and saved history.

### 2. Personal progress

Fresh new accounts and isolated profile/progress storage.

Source: commit `fef28de` — Start real accounts fresh and isolate saved profiles and progress.

### 3. Navigation and social demo

Phone navigation, quest browsing, active tasks and simulated friends.

Source: commit `f77cefd` — Add presentation bots, quest browsing, active tasks and audio motion polish.

### 4. Quest connections

Full prerequisite map; category colours followed in 2bca901.

Source: commit `e9cac06` — Show every quest and prerequisite connection in the activity tree.

### 5. Verification and lifecycle

Photo checks, pause/resume refinements and a two-active-task limit; background timers followed in 0990f62.

Source: commit `2598d0d` — Fix paused quest navigation, limit active tasks and quiet app audio.

### 6. Rewards and identity

Demo tokens, reward offers and visible club badges; three selectable badges followed in de91e9c.

Source: commit `25f2328` — Add demo token rewards, club badges and interactive quest tree.

### 7. Direct Gemini and presentation polish

Server-only photo-verification gateway; active pulses, gesture isolation, demo reset and SQ identity followed.

Source: commit `2aa9742` — Use a server-only direct Gemini gateway for photo verification.

### 8. Club discovery and themes

Public/private clubs, join approvals, cloud membership and a calm light theme.

Source: commit `5522f67` — Add club discovery, private join approvals and a calm light theme.

## Suggested demo sequence

Login → onboarding → Home → Quests → start/pause task → completion and suggestions → Activity Log → Progress connections → club discovery → shared tasks and members → group chat → rewards and badges → light theme.

## Recreate the package

Capture JPEGs through the browser at 440 × 956, then run `python artifacts/screenshots/package_screenshots.py` with Pillow installed. The welcome-only fixture is available at `http://localhost:8085/?screen=welcome`.
