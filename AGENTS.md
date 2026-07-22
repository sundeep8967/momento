# AGENTS.md — Momento Project Guidelines

## Overview
**Momento** is a private, ephemeral photo/video social app built with Flutter, Firebase, Cloudinary, and Isar local database. The app features end-to-end media sharing, real-time messaging, streaks, and custom brand themes inspired by Snapchat and Apple HIG.

---

## 🎨 Theme & Brand Guidelines

### Color System (`SetlogColors` in `lib/theme/colors.dart`)
- **Primary Brand Color (`momentoPink`)**: `Color(0xFFE8729A)` — Vibrant brand pink used for CTAs, active tab icons, buttons, and highlights.
- **Snap Viewing Accent (`snapViewerAccent`)**: `Color(0xFFE5366A)` — Deep rose/red used for unread indicators, viewer accents, and action highlights (analogous to Snapchat red).
- **Surface / Background**: `Color(0xFFFDF4F8)` / `Color(0xFFF7F7F7)` — Warm, clean iOS-inspired canvas background.
- **Camera Canvas**: `Color(0xFF1A0A10)` — Near-black warm background.
- **Card Borders**: `Color(0xFFEFB8CF)` (`momentoPinkBorder`).

### Design Aesthetic (Apple HIG + Snapchat Vibe)
- **Typography**: Native `.SF Pro Text` font family.
- **Navigation**: iOS `CupertinoSliverNavigationBar` and glassmorphic translucent headers.
- **Home / Chat Screen**: Snapchat-inspired layout with left accent color bars, unread status dots, streak fire counters (`🔥`), and ghost chat bubble icons.
- **App Launcher Icon**: Rounded squircle icon featuring the Momento dog mascot wearing a pink cap.

---

## 🏗️ Architecture & Core Components

```
lib/
├── data/
│   ├── snap_repository.dart       # DirectSnap Firestore fan-out model & inbox streams
│   ├── friends_repository.dart    # UserProfile & friendship relationship management
│   ├── log_repository.dart        # Private video journal logs
│   ├── cloudinary_service.dart    # Media uploads with q_auto, f_auto optimization
│   ├── encryption_service.dart    # End-to-end media/data encryption
│   ├── local_cache.dart           # Fast Isar local database caching
│   ├── push_notification_service.dart # FCM notifications setup
│   └── video_proxy_server.dart    # Local proxy for streaming encrypted video
├── presentation/
│   ├── splash/                    # Animated splash screen with rounded mascot logo
│   ├── auth/                      # Onboarding & Authentication flows
│   ├── main/                      # Core feature screens
│   │   ├── collections_home_screen.dart # Snapchat-style chat list home view
│   │   ├── camera_capture_screen.dart   # Camera & media recording UI
│   │   ├── snap_viewer_screen.dart      # Fullscreen moment viewer with progress bar
│   │   ├── send_to_screen.dart          # Send moment to friends/groups with instant cache
│   │   ├── friends_screen.dart          # Friends & request management
│   │   └── profile_screen.dart          # User profile & streak stats
│   └── groups/                    # Group chat & shared moments management
├── router/
│   └── app_router.dart            # GoRouter configuration & page transitions
└── theme/
    └── colors.dart                # SetlogColors palette & setlogTheme definitions
```

---

## 🛠️ Key Technical Rules & Patterns

1. **State Management**: Use `flutter_riverpod` (`ConsumerStatefulWidget` / `ref.read`).
2. **Navigation**: Use `go_router` (`context.push`, `context.go`).
3. **Data Fetching**: Cache-first loading via `LocalCache` (Isar) before triggering network refreshes.
4. **Media Optimization**: Always inject `q_auto,f_auto` flags into Cloudinary URLs for efficient bandwidth usage.
5. **Iconography**: Use `CupertinoIcons` across all iOS components rather than standard Material icons.

---

## ⚡ Development Philosophy (Ponytail Mindset)
1. **Does it need to exist?** → Skip if unnecessary (YAGNI).
2. **Already in codebase?** → Reuse, do not rewrite.
3. **Stdlib/Platform does it?** → Use native features or installed dependencies.
4. **Minimum code**: Write the simplest implementation that achieves the target UX without sacrificing security or performance.
