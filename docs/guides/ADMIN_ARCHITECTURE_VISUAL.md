# 👑 Admin System Architecture - Visual Guide

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    NEXTWAVE GAME APP                             │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 USER INTERFACE LAYER                        │ │
│  │                                                             │ │
│  │  ┌──────────────────┐         ┌──────────────────┐        │ │
│  │  │ Settings Screen  │         │ Admin Dashboard  │        │ │
│  │  │                  │         │                  │        │ │
│  │  │ [Regular User]   │         │ [Admin Only]     │        │ │
│  │  │  - Account       │  ═══>   │  - Statistics    │        │ │
│  │  │  - Notifications │         │  - Quick Actions │        │ │
│  │  │  - Privacy       │         │  - Admin Mgmt    │        │ │
│  │  │  - Logout        │         │  - Error Logs    │        │ │
│  │  │                  │         │  - Danger Zone   │        │ │
│  │  │ [if isAdmin]     │         │                  │        │ │
│  │  │  👑 Admin Card   ├────────>│                  │        │ │
│  │  └──────────────────┘         └──────────────────┘        │ │
│  │                                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  SERVICE LAYER                              │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │         AdminService (Singleton)                     │  │ │
│  │  │                                                       │  │ │
│  │  │  • isAdmin() - Check admin status ✅                 │  │ │
│  │  │  • grantAdminAccess(userId) 👥                       │  │ │
│  │  │  • revokeAdminAccess(userId) ❌                      │  │ │
│  │  │  • initializeNPCs() 🤖                               │  │ │
│  │  │  • triggerDailyUpdate() 📅                           │  │ │
│  │  │  • sendGlobalNotification() 📢                       │  │ │
│  │  │  • getGameStats() 📊                                 │  │ │
│  │  │  • getErrorLogs() 🐛                                 │  │ │
│  │  │  • resetAllPlayerData() ⚠️                           │  │ │
│  │  │                                                       │  │ │
│  │  │  [Security Check on Every Operation]                 │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │                              ↓                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              FIREBASE BACKEND                               │ │
│  │                                                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │ │
│  │  │  Firestore   │  │  Functions   │  │  Authentication │  │ │
│  │  │              │  │              │  │                 │  │ │
│  │  │  admins/     │  │  initialize  │  │  User UIDs      │  │ │
│  │  │  players/    │  │  NPCArtists  │  │                 │  │ │
│  │  │  npc_artists/│  │  trigger     │  │  [Your UID]     │  │ │
│  │  │  error_logs/ │  │  DailyUpdate │  │  [Admin UIDs]   │  │ │
│  │  │  system_     │  │  ...         │  │                 │  │ │
│  │  │  notif's/    │  │              │  │                 │  │ │
│  │  └──────────────┘  └──────────────┘  └─────────────────┘  │ │
│  │                                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Admin Access Flow

```
┌──────────────┐
│  Game Start  │
└──────┬───────┘
       │
       ▼
┌───────────────────────┐
│  User opens Settings  │
└──────────┬────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│  AdminService.isAdmin()                 │
│                                         │
│  1. Check cached status                 │
│  2. Check ADMIN_USER_IDS list          │
│  3. Query Firestore admins collection   │
│  4. Cache result                        │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
┌─────────┐      ┌───────────────┐
│ isAdmin │      │ NOT an Admin  │
│  = true │      │   = false     │
└────┬────┘      └───────┬───────┘
     │                   │
     │                   ▼
     │           ┌──────────────────┐
     │           │  Settings Only   │
     │           │  - Account       │
     │           │  - Notifications │
     │           │  - Privacy       │
     │           │  - Logout        │
     │           │                  │
     │           │ [No Admin UI]    │
     │           └──────────────────┘
     │
     ▼
┌──────────────────────────────────┐
│  Settings + Admin Section        │
│  - Account                       │
│  - Notifications                 │
│  - Privacy                       │
│  - Logout                        │
│                                  │
│  👑 ADMIN DASHBOARD CARD 👑      │
│  [Glowing Blue Gradient]         │
│  [Click to Open Dashboard]       │
└─────────────┬────────────────────┘
              │
              │ User clicks "OPEN ADMIN DASHBOARD"
              │
              ▼
┌──────────────────────────────────────┐
│  Admin Dashboard Screen              │
│                                      │
│  📊 Game Statistics                  │
│     - Players, Songs, NPCs, Posts    │
│                                      │
│  ⚡ Quick Actions                    │
│     - Initialize NPCs                │
│     - Trigger Daily Update           │
│     - Send Global Notification       │
│                                      │
│  👥 Admin Management                 │
│     - View admins                    │
│     - Grant access                   │
│     - Revoke access                  │
│                                      │
│  🐛 Error Logs                       │
│     - Recent errors from all players │
│                                      │
│  ⚠️  Danger Zone                     │
│     - Reset all data (with confirm)  │
└──────────────────────────────────────┘
```

---

## Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                   SECURITY ARCHITECTURE                      │
│                                                              │
│  Layer 1: UI Protection                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  if (_isAdmin) {                                       │ │
│  │    // Show admin features                              │ │
│  │  }                                                      │ │
│  │                                                         │ │
│  │  ✅ Non-admins never see admin UI                      │ │
│  │  ✅ No hints that admin features exist                 │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  Layer 2: Service-Level Checks                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Future<void> adminOperation() async {                 │ │
│  │    if (!await isAdmin()) {                             │ │
│  │      throw Exception('Admin access required');         │ │
│  │    }                                                    │ │
│  │    // Perform operation                                │ │
│  │  }                                                      │ │
│  │                                                         │ │
│  │  ✅ Every operation validates admin status             │ │
│  │  ✅ Can't bypass by manipulating UI                    │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  Layer 3: Hardcoded Admin IDs                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  static const List<String> ADMIN_USER_IDS = [          │ │
│  │    'YOUR_USER_ID',                                     │ │
│  │  ];                                                     │ │
│  │                                                         │ │
│  │  ✅ Compiled into app                                  │ │
│  │  ✅ Can't be changed by users                          │ │
│  │  ✅ Fastest check (no network)                         │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  Layer 4: Firestore Validation                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  admins/{userId}                                       │ │
│  │    isAdmin: true                                       │ │
│  │    grantedBy: (admin who granted)                      │ │
│  │    grantedAt: (timestamp)                              │ │
│  │                                                         │ │
│  │  ✅ Dynamic admin management                           │ │
│  │  ✅ Can grant/revoke from dashboard                    │ │
│  │  ✅ Auditable (who granted when)                       │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  Layer 5: Firestore Security Rules (Optional)               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  function isAdmin() {                                  │ │
│  │    return exists(/databases/.../admins/$(uid))         │ │
│  │           && get(...).data.isAdmin == true;            │ │
│  │  }                                                      │ │
│  │                                                         │ │
│  │  match /admins/{userId} {                              │ │
│  │    allow read, write: if isAdmin();                    │ │
│  │  }                                                      │ │
│  │                                                         │ │
│  │  ✅ Server-side validation                             │ │
│  │  ✅ Can't bypass with modified client                  │ │
│  │  ✅ Defense in depth                                   │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Admin Operation Flow

### Example: Initialize NPCs

```
┌──────────────────────┐
│  User clicks         │
│  "Initialize NPCs"   │
│  in Admin Dashboard  │
└──────────┬───────────┘
           │
           ▼
┌───────────────────────────────────┐
│  AdminDashboardScreen             │
│  _initializeNPCs()                │
│                                   │
│  1. Show loading dialog           │
└──────────┬────────────────────────┘
           │
           ▼
┌───────────────────────────────────┐
│  AdminService                     │
│  initializeNPCs()                 │
│                                   │
│  1. Check isAdmin() ✅            │
│  2. If not admin → throw error    │
│  3. If admin → proceed            │
└──────────┬────────────────────────┘
           │
           ▼
┌───────────────────────────────────┐
│  Firebase Functions               │
│  initializeNPCArtists()           │
│                                   │
│  1. Check _initialized flag       │
│  2. Create 10 signature NPCs      │
│  3. Generate songs for each       │
│  4. Save to npc_artists/          │
│  5. Set _initialized = true       │
└──────────┬────────────────────────┘
           │
           ▼
┌───────────────────────────────────┐
│  Firestore Database               │
│                                   │
│  npc_artists/                     │
│    npc_jaylen_sky/   ← Created   │
│    npc_luna_grey/    ← Created   │
│    npc_hana_seo/     ← Created   │
│    ... (10 total)                 │
│    _initialized/     ← Flag set   │
└──────────┬────────────────────────┘
           │
           ▼
┌───────────────────────────────────┐
│  Response back to AdminService    │
│                                   │
│  {                                │
│    success: true,                 │
│    count: 10,                     │
│    signatureNPCs: 10,             │
│    totalSongs: 67                 │
│  }                                │
└──────────┬────────────────────────┘
           │
           ▼
┌───────────────────────────────────┐
│  AdminDashboardScreen             │
│                                   │
│  1. Close loading dialog          │
│  2. Show success dialog           │
│  3. Refresh game stats            │
└───────────────────────────────────┘
           │
           ▼
┌───────────────────────────────────┐
│  🎉 NPCs now available to         │
│     ALL PLAYERS GLOBALLY!         │
└───────────────────────────────────┘
```

---

## Data Flow Diagram

```
                        ┌──────────────────┐
                        │   Admin User     │
                        └────────┬─────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
          ┌───────────────────┐    ┌──────────────────┐
          │  Settings Screen  │    │ Admin Dashboard  │
          │                   │    │                  │
          │  • View profile   │    │ • View stats     │
          │  • Edit settings  │    │ • Perform actions│
          │  • See admin card │    │ • Manage admins  │
          └─────────┬─────────┘    └────────┬─────────┘
                    │                       │
                    └──────────┬────────────┘
                               │
                               ▼
                    ┌────────────────────┐
                    │   AdminService     │
                    │                    │
                    │  • Cache status    │
                    │  • Validate ops    │
                    │  • Call Firebase   │
                    └──────────┬─────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
     ┌─────────────────┐  ┌─────────┐  ┌──────────┐
     │   Firestore     │  │Functions│  │   Auth   │
     │                 │  │         │  │          │
     │  • admins/      │  │• initNPC│  │• User ID │
     │  • players/     │  │• daily  │  │• Token   │
     │  • npc_artists/ │  │• notify │  │          │
     │  • error_logs/  │  │         │  │          │
     └─────────────────┘  └─────────┘  └──────────┘
                │              │              │
                └──────────────┼──────────────┘
                               │
                               ▼
                    ┌────────────────────┐
                    │  All operations    │
                    │  return results    │
                    └────────────────────┘
                               │
                               ▼
                    ┌────────────────────┐
                    │  UI updates with   │
                    │  success/error     │
                    └────────────────────┘
```

---

## User Perspective Comparison

### Regular Player View

```
┌─────────────────────────────────┐
│         Settings                │
├─────────────────────────────────┤
│                                 │
│  ACCOUNT                        │
│  ┌───────────────────────────┐  │
│  │  👤 Player Name           │  │
│  │  📧 No email              │  │
│  └───────────────────────────┘  │
│                                 │
│  NOTIFICATIONS                  │
│  ┌───────────────────────────┐  │
│  │  🔔 Push Notifications   │  │
│  │  🔊 Sound                │  │
│  └───────────────────────────┘  │
│                                 │
│  PRIVACY                        │
│  ┌───────────────────────────┐  │
│  │  👁️  Show Online Status   │  │
│  └───────────────────────────┘  │
│                                 │
│  ACCOUNT ACTIONS                │
│  ┌───────────────────────────┐  │
│  │  🚪 LOGOUT                │  │
│  │  🗑️  DELETE ACCOUNT        │  │
│  └───────────────────────────┘  │
│                                 │
│  [That's it - no admin stuff!]  │
│                                 │
└─────────────────────────────────┘
```

### Admin (Your) View

```
┌─────────────────────────────────┐
│         Settings                │
├─────────────────────────────────┤
│                                 │
│  ACCOUNT                        │
│  ┌───────────────────────────┐  │
│  │  👤 Player Name           │  │
│  │  📧 No email              │  │
│  └───────────────────────────┘  │
│                                 │
│  NOTIFICATIONS                  │
│  ┌───────────────────────────┐  │
│  │  🔔 Push Notifications   │  │
│  │  🔊 Sound                │  │
│  └───────────────────────────┘  │
│                                 │
│  PRIVACY                        │
│  ┌───────────────────────────┐  │
│  │  👁️  Show Online Status   │  │
│  └───────────────────────────┘  │
│                                 │
│  ACCOUNT ACTIONS                │
│  ┌───────────────────────────┐  │
│  │  🚪 LOGOUT                │  │
│  │  🗑️  DELETE ACCOUNT        │  │
│  └───────────────────────────┘  │
│                                 │
│  👑 ADMIN DASHBOARD 👑          │
│  ┌───────────────────────────┐  │
│  │  ╔═══════════════════════╗│  │
│  │  ║   🎛️ Admin Access    ║│  │
│  │  ║                       ║│  │
│  │  ║  You have admin       ║│  │
│  │  ║  privileges.          ║│  │
│  │  ║                       ║│  │
│  │  ║ [OPEN DASHBOARD]      ║│  │
│  │  ╚═══════════════════════╝│  │
│  └───────────────────────────┘  │
│                                 │
│  [Exclusive admin access!] ✨   │
│                                 │
└─────────────────────────────────┘
```

---

## Summary Flow Chart

```
        START
          │
          ▼
    ┌──────────┐
    │ App Init │
    └────┬─────┘
         │
         ▼
    ┌─────────────┐
    │ User Login  │
    └─────┬───────┘
          │
          ▼
    ┌──────────────────┐
    │ Check if Admin?  │
    └────┬─────┬───────┘
         │     │
    YES  │     │  NO
         │     │
         ▼     ▼
    ┌────────┐ ┌────────┐
    │ Admin  │ │Regular │
    │  UI    │ │   UI   │
    └───┬────┘ └────────┘
        │
        ▼
    ┌─────────────────┐
    │ Admin Dashboard │
    │   Available     │
    └────┬────────────┘
         │
         ├─> Initialize NPCs
         ├─> Send Notifications
         ├─> View Statistics
         ├─> Manage Admins
         ├─> View Error Logs
         └─> Reset Data
              │
              ▼
         ┌─────────────┐
         │ Operations  │
         │ Affect ALL  │
         │ Players 🌍  │
         └─────────────┘
```

---

*Visual Architecture Guide*  
*Created: October 17, 2025*  
*Illustrates the complete admin system flow*
