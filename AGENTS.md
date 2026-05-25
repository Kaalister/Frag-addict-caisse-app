<claude-mem-context>
# Memory Context

# [FragsAddicts] imported project context, merged 2026-05-25

Active project root: `/Users/kaalister/Personnel/Frag-addict-caisse-app`.
The previous `/Users/kaalister/Personnel/FragsAddicts` location is no longer the app repository; its remaining `AGENTS.md` context was merged here after the move.

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Imported observations available in the two local snapshots: 52-107 and 744-771.

### May 7, 2026
52 11:11a 🟣 FirebaseSyncService Implemented — Full Snapshot Push/Pull with Last-Write-Wins Logic
54 11:12a 🟣 Auth-Gated App Shell — LoginPage Shown When No Firebase User, Sync on Auth State Change
55 " 🟣 LoginPage Widget Implemented — Email/Password Firebase Auth UI
56 11:13a 🟣 Firebase Sync UI Added to ConfigPage — Status, Manual Sync Button, and Logout
57 11:15a 🔵 flutter analyze Found 2 Blocking Errors — Transaction Name Conflict and await in Wrong Context
58 11:16a 🔴 Two Compiler Errors Fixed — Transaction Ambiguity Resolved and await_in_wrong_context Fixed
59 " 🔴 flutter analyze Now Shows 0 Errors — Down from 28 Issues to 26 (Warnings/Info Only)
60 " ✅ flutter analyze Clean — 25 Info-Only Issues, Zero Errors or Warnings
61 " 🔵 Existing Unit Test Exercises money() Formatter — flutter test Running Post-Integration
62 11:17a ✅ flutter test Passes and Debug APK Build Launched
63 " 🔵 Android SDK Platform 34 Auto-Installed During Debug APK Build
64 " 🔵 cloud_firestore 6.3.0 Android Java Compilation Shows Unchecked Operations Note
65 " 🟣 Android Debug APK Built Successfully with Firebase — build/app/outputs/flutter-apk/app-debug.apk
66 11:19a ✅ FIREBASE_SETUP.md Created — Complete Manual Setup Guide for Firebase Console Steps
67 " ✅ README.md Updated with Firebase Sync Section
68 " 🟣 Firebase Integration Complete — All 5 Plan Steps Done, Code Verified In-Place
74 12:24p 🔵 flutterfire CLI Installed But Not on PATH — zsh: command not found on macOS
75 12:31p 🔵 Firebase CLI Authenticated as darksouls22darksouls@gmail.com — Account Confirmed for Project Setup
76 12:38p 🔵 User Reached End of Manual Firebase Setup Steps
77 12:39p 🟣 firebase_options.dart Generated with Real Credentials
78 " 🟣 Firebase Integration Fully Wired — All Artifacts Present
79 " 🔵 flutter test and flutter analyze Pass Clean After Firebase Integration
80 " 🟣 Android Debug APK Builds Successfully with Full Firebase Stack
81 12:40p ⚖️ User Requests Optional Firebase Mode — No Forced Login
82 12:56p 🔵 Current Firebase Auth-Gating Logic in _RootShellState
83 12:57p 🟣 Firebase Auth Made Optional — App No Longer Requires Login to Launch
84 " 🟣 ConfigPage Firebase Section Gets Login/Logout Toggle Buttons
85 " 🟣 showFirebaseLoginDialog and _signInFirebaseFromDialog Implemented
86 " 🔴 Fixed snack Context After Dialog Dismiss in _signInFirebaseFromDialog
87 12:58p 🟣 Optional Firebase APK Builds Successfully in 10.8s (Incremental)
88 " 🔵 Auto-Sync on Sign-In Removed — Sign-In Becomes Fully Manual
89 1:01p 🔵 Import Order Mismatch Caused Patch Failure — dart:async Before dart:convert
90 " 🔄 Removed authStateChanges Listener — _RootShellState Fully Simplified
91 " 🔄 Firebase Login Dialog Refactored — syncNow Moved to Dialog Caller
92 " 🟣 AppController.disconnectFirebase() Added for Clean Sign-Out
93 1:02p 🟣 ConfigPage Logout Button Wired to controller.disconnectFirebase()
94 " 🟣 Optional Firebase Feature Complete — Final APK Verified Clean
95 " 🔵 Two Runtime Bugs Found on First Device Test
96 1:06p 🔵 AppController.load() Calls syncNow on Startup When Firebase Available
97 " 🔴 Removed Auto-Sync from load() — App No Longer Syncs on Startup
98 1:07p 🔴 Friendly Error Messages Added for Firestore Sync Failures
99 " 🔵 Patch for _friendlySyncError Failed Due to Single-Quote Encoding Mismatch
100 " 🔴 Login Dialog setState Callbacks Guard Against Unmounted Context
101 " 🔴 ConfigActionZone Made Responsive — Fixed RenderFlex Overflow
102 1:08p 🔄 Firebase Login Dialog Extracted to _FirebaseLoginDialog StatefulWidget
103 " 🟣 All Device Bug Fixes Compiled — Final APK Ready for Re-Test
104 1:11p 🔵 Flutter InheritedElement Assertion Crash on Login — Widget Tree Lifecycle Bug
105 1:12p 🔵 _FirebaseLoginDialog Refactor Was Not Applied — Code Reverted to StatefulBuilder
106 " 🔄 Dead LoginPage StatefulWidget Removed from Codebase
107 " 🟣 Firebase Login Moved from Dialog to Inline Panel in ConfigPage
### May 21, 2026
744 6:40p 🟣 Export Button Requested for Stats Section (PDF KPI Report)
745 " 🔵 FragsAddicts Project Root Contains Only AGENTS.md
746 " 🔵 Frag-addict-caisse-app is a Flutter App with PDF Dependency Already Present
747 6:41p 🔵 Existing PDF Export Infrastructure in lib/main.dart — Players List Already Exportable
748 " 🔵 Reference KPI PDF is a Samsung-Produced Document — Content Inaccessible Without pdftotext
749 6:42p 🔵 Reference KPI PDF Content Fully Decoded — 5-Section Report with Charts and Tables
750 " 🟣 Export Button Added to KpiPage ("Stats" Tab)
751 6:43p 🟣 exportKpiPdf() Implemented — 3-Page KPI PDF with Tables and Bar Charts
752 " 🔵 flutter analyze Passes — Only Pre-Existing Info-Level Style Warnings
753 " 🔴 Lint Fixes Applied to exportKpiPdf() — Curly Braces and Parameter Name
754 6:44p 🟣 KPI PDF Export Feature Fully Implemented and Tests Pass
755 " 🟣 KPI PDF Export Feature Builds Successfully — Debug APK Produced
756 " 🔵 Git Repo Contains Deleted Legacy FragsAddicts/ Subdirectory — Only lib/main.dart Changed in Active Code
S224 Flutter KPI PDF export feature — cross-session article stats aggregation via _kpiAllSales(), then reverted after user's truncated message (May 21 at 6:55 PM)
757 7:03p 🔴 KPI PDF Section 4 category breakdown re-enabled cross-session aggregation
S225 Investigating why Section 4 (Répartition CA par catégorie) shows MUNITIONS 5.00 despite no BB/gas purchases in the current session (May 21 at 7:09 PM)
758 7:33p 🔵 FragsAddicts project at /Users/kaalister/Personnel/FragsAddicts is not a git repo
759 " 🔵 Actual Flutter caisse app lives at Frag-addict-caisse-app, not FragsAddicts
760 " 🔵 Frag-addict-caisse-app already has two PDF export functions using the `pdf` package
761 " 🔵 Git repo reorganized: FragsAddicts/ subfolder deleted, project now lives at repo root
762 7:37p 🔵 CashAnalysisPage data model fully mapped — sufficient for caisse PDF export
763 " 🔵 Reference PDF is a Samsung scan, not app-generated — content is binary-compressed and unreadable via strings
764 " 🔵 Complete PDF save/build infrastructure documented in lib/main.dart
765 " 🔵 Reference PDF layout fully decoded — exact structure for exportCashPdf implementation confirmed
766 7:38p 🟣 PDF export button added to CashAnalysisPage's "Caisse espèces" section header
767 7:39p 🟣 exportCashPdf and _buildCashPdf implemented — full caisse analysis PDF export added
768 7:40p 🔴 _pdfCompactTimestamp string interpolation fixed — $day_ ambiguity resolved with ${day}
769 7:41p 🔵 flutter analyze returns 29 pre-existing info warnings — zero issues from new caisse PDF code
770 " 🟣 lib/main.dart diff confirmed — 262 lines added for caisse PDF export feature, single file modified
771 " 🟣 Android debug APK built successfully — caisse PDF export feature fully compiled and verified

This imported snapshot is the locally available handoff context for future work in the relocated repository.
</claude-mem-context>
