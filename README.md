# 🎵 NextWave - Music Artist Life Simulation Game

A mobile music artist life simulation game built with Flutter and Firebase. Rise from an unknown artist to global stardom by creating music, building your fanbase, and dominating the charts!

## 🎮 Features

### Core Gameplay
- **Song Creation System**: Write songs in 9 different genres (R&B, Hip Hop, Rap, Trap, Drill, Afrobeat, Country, Jazz, Reggae)
- **Skills Progression**: Improve your Songwriting, Lyrics, Composition, Experience, and Inspiration
- **World Travel**: Travel between 7 global regions (USA, Europe, UK, Asia, Africa, Latin America, Oceania)
- **Professional Studios**: Record at 15+ real-world inspired studios with varying quality and costs
- **Tunify Streaming Platform**: Release songs and track streams, likes, and earnings
- **The Spotlight Charts**: Billboard-style leaderboards with Hot 100, Top Artists, and Spotlight 200

### Multiplayer Features
- **Firebase Authentication**: Sign up with email or play as guest
- **Artist Onboarding**: Create your artist profile with name, genre, region, and bio
- **Global Leaderboards**: Compete with players worldwide
- **Real-time Charts**: See trending songs and rising artists

### Game Mechanics
- **Energy System**: Actions cost energy (Write Song, Perform Concert, Record Album, Practice Skills, Social Media, Rest)
- **Quality Calculation**: Song quality based on skills, effort level, and genre bonuses
- **Regional Popularity**: Different genres perform better in different regions
- **Studio Bonuses**: Premium studios and producers boost recording quality
- **Streaming Economics**: Earn money from streams ($0.003 per stream)

## � Documentation

All project documentation has been organized into the `/docs` directory:

- **[Documentation Index](docs/README.md)** - Complete documentation navigation
- **[Quick Start Guide](docs/guides/QUICK_START.md)** - Get started quickly
- **[Game Overview](docs/guides/GAME_OVERVIEW.md)** - Comprehensive game mechanics
- **[All Features](docs/ALL_FEATURES_SUMMARY.md)** - Complete feature list
- **[Latest Release Notes](docs/releases/)** - Version history

### Key Documentation

- 📖 **Systems**: Core game mechanics and technical systems
- 🎨 **Features**: Specific game features and implementations
- 📝 **Guides**: User guides and quick references
- 🔧 **Fixes**: Bug fixes and patches
- 🚀 **Releases**: Version history and changelogs
- ⚙️ **Setup**: Installation and configuration

## �🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.8.1 or higher)
- Firebase account
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/NextWave.git
   cd NextWave/mobile_game
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase** (Required for multiplayer features)
   
   Option A: Use the setup script (Windows PowerShell):
   ```powershell
   .\setup_firebase.ps1
   ```
   
   Option B: Manual setup:
   - See [docs/setup/FIREBASE_SETUP.md](docs/setup/) for detailed instructions
   - Or run: `flutterfire configure`

4. **Run the app**
   ```bash
   # Web
   flutter run -d chrome
   
   # Android
   flutter run -d android
   
   # iOS
   flutter run -d ios
   ```

## 📱 Supported Platforms

- ✅ Web (Chrome, Edge, Firefox, Safari)
- ✅ Android (5.0+)
- ✅ iOS (12.0+)
- ✅ Windows (Desktop)
- ⚠️ macOS (Desktop) - Experimental
- ⚠️ Linux - Experimental

## 🎨 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── game.dart                 # Flame game engine (legacy)
├── models/                   # Data models
│   ├── artist_stats.dart     # Player stats & skills
│   ├── song.dart             # Song model with states
│   ├── published_song.dart   # Multiplayer song model
│   ├── multiplayer_player.dart # Player profile model
│   ├── studio.dart           # Studio system
│   └── world_region.dart     # World regions
├── screens/                  # UI screens
│   ├── auth_screen.dart      # Sign up / Login
│   ├── onboarding_screen.dart # Artist profile setup
│   ├── dashboard_screen_new.dart # Main game screen
│   ├── world_map_screen.dart # Travel interface
│   ├── studios_list_screen.dart # Studio browser
│   ├── tunify_screen.dart    # Streaming platform
│   └── leaderboard_screen.dart # Global charts
├── services/                 # Backend services
│   ├── firebase_service.dart # Real Firebase integration
│   └── demo_firebase_service.dart # Offline demo mode
└── utils/                    # Utilities
    └── firebase_status.dart  # Firebase status checker
```

## 🎵 Game Genres

Each genre has unique characteristics and regional popularity:

| Genre | Emoji | Best Regions |
|-------|-------|--------------|
| R&B | 🎤 | USA, UK |
| Hip Hop | 🎧 | USA, Europe |
| Rap | 🎙️ | USA, Europe |
| Trap | 🔥 | USA, Latin America |
| Drill | 🔫 | UK, USA |
| Afrobeat | 🥁 | Africa, UK |
| Country | 🤠 | USA, Oceania |
| Jazz | 🎷 | Europe, USA |
| Reggae | 🌴 | Latin America, Africa |

## 🌍 World Regions

| Region | Population | Cost Multiplier | Top Genres |
|--------|-----------|-----------------|------------|
| USA | 2.5B | 1.0x | Hip Hop, Rap, Country |
| Europe | 2.0B | 1.2x | Jazz, R&B, Hip Hop |
| UK | 800M | 1.3x | Drill, R&B |
| Asia | 1.5B | 0.8x | Various |
| Africa | 700M | 0.6x | Afrobeat, Reggae |
| Latin America | 600M | 0.7x | Trap, Reggae |
| Oceania | 400M | 1.1x | Country, Hip Hop |

## 🎙️ Studio System

**Studio Tiers:**
- 👑 Legendary (95-98% quality, $15K-$18K)
- ⭐ Professional (85-92% quality, $8K-$12K)
- 💎 Premium (75-85% quality, $4K-$6K)
- 🎵 Standard (65-75% quality, $2K-$3K)
- 🎤 Budget (60-70% quality, $500-$1.5K)

**Studio Features:**
- Quality rating affects final song quality
- Reputation bonus (50-100 points)
- Genre specialties (+15% bonus)
- Optional producer hire (15-20% boost)
- Regional pricing based on cost of living

## 📊 Skills System

| Skill | Effect | Max Level |
|-------|--------|-----------|
| Songwriting | Song quality | 100 |
| Lyrics | Song quality | 100 |
| Composition | Song quality | 100 |
| Experience | Overall bonus | 100 |
| Inspiration | Creativity | 100 |

**Skill Gain:**
- Writing songs: +2-5 per skill (varies by effort and genre)
- Practice Skills action: Focused improvement
- Natural decay: Skills slowly decrease without practice

## 🏆 The Spotlight Charts

Billboard-style leaderboards with three tabs:

1. **Hot 100**: Top 100 songs by streams
2. **Top Artists**: Top 50 artists by total streams
3. **Spotlight 200**: Extended chart with 200 songs

**Chart Stats:**
- Streams: Total play count
- LW: Last week ranking
- PEAK: Highest position achieved
- WKS: Weeks on chart
- NEW: Badge for entries within 7 days

## 🔥 Firebase Integration

The game uses Firebase for:
- **Authentication**: Email/password and anonymous sign-in
- **Firestore**: Player profiles and published songs
- **Analytics**: User engagement tracking
- **Real-time Leaderboards**: Global competition

### Firestore Collections

**players:**
```javascript
{
  id: string,
  displayName: string,
  email: string,
  isGuest: boolean,
  primaryGenre: string,
  homeRegion: string,
  bio: string,
  totalStreams: number,
  totalLikes: number,
  totalSongs: number,
  joinDate: timestamp,
  lastActive: timestamp,
  rankTitle: string
}
```

**published_songs:**
```javascript
{
  id: string,
  playerId: string,
  playerName: string,
  title: string,
  genre: string,
  quality: number,
  streams: number,
  likes: number,
  releaseDate: timestamp
}
```

## 🎮 How to Play

1. **Sign up** or continue as guest
2. **Complete onboarding**: Choose artist name, genre, and region
3. **Write songs**: Select genre and effort level
4. **Travel** to different regions for better opportunities
5. **Record** at professional studios to boost quality
6. **Release** songs to Tunify streaming platform
7. **Track performance** with analytics
8. **Climb the charts** and compete globally!

## 🛠️ Development

### Running in Development Mode

```bash
# Hot reload enabled
flutter run

# With specific device
flutter run -d chrome
flutter run -d android

# Release mode
flutter run --release
```

### Building for Production

```bash
# Web
flutter build web

# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Contact

For questions or feedback, please open an issue on GitHub.

## 🎉 Credits

- Built with [Flutter](https://flutter.dev/)
- Game engine: [Flame](https://flame-engine.org/)
- Backend: [Firebase](https://firebase.google.com/)
- Inspired by music industry simulation games

---

Made with ❤️ for music lovers and aspiring artists worldwide 🌍🎵
