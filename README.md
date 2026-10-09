# Melody - Music Player

### APK Download

You can download and install the release APK directly:
- **Download APK**: [Download app-release.apk](apk/app-release.apk) *(or find it in the repository under the `apk/` directory or GitHub Releases)*

---

### Setup Instructions

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd musicapp
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

4. Build release APK:
   ```bash
   flutter build apk --release
   ```
   The output APK will be generated at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

### Architecture & State Management

The project is structured with a clean separation of concerns using the MVC pattern and **Provider** (`ChangeNotifier`) for state management:

- **Models (`lib/models/`)**: Defines the `Track` data model, handling JSON serialization from the Jamendo API as well as local disk caching properties (`isDownloaded`, `localPath`, `localImagePath`).
- **Services (`lib/services/`)**:
  - `ApiService`: Manages network requests to Jamendo endpoints (pagination, search, error handling).
  - `DownloadService`: Downloads actual MP3 audio files and album artwork to the device storage via `Dio` and `path_provider`, and persists offline track lists in `SharedPreferences`.
- **State Management (`lib/providers/`)**:
  - `MusicProvider`: Acts as the central controller. It listens to audio streams from `just_audio` / `just_audio_background`, manages playback queues, handles live debounced search, tracks download progress, and detects offline connectivity status.
- **Views (`lib/views/`)**:
  - UI screens (`SplashScreen`, `HomeScreen`, `SearchScreen`, `NowPlayingScreen`) and modular widgets (`TrackTile`, `MiniPlayer`) observe changes through Provider's `Consumer` widgets and update reactively.
