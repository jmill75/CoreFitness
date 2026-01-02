import SwiftUI
import MusicKit
import MediaPlayer

// MARK: - Music Service
@MainActor
class MusicService: ObservableObject {
    static let shared = MusicService()

    @Published var isPlaying = false
    @Published var currentTrack: MusicTrack?
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var selectedProvider: MusicProvider = .appleMusic
    @Published var currentPlaybackTime: TimeInterval = 0

    private let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var pollingTimer: Timer?

    // MARK: - Music Provider
    enum MusicProvider: String, CaseIterable, Identifiable {
        case appleMusic = "Apple Music"
        case spotify = "Spotify"
        case amazonMusic = "Amazon Music"
        case youtubeMusic = "YouTube Music"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .appleMusic: return "applelogo"
            case .spotify: return "music.note"
            case .amazonMusic: return "music.note.list"
            case .youtubeMusic: return "play.rectangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .appleMusic: return .red
            case .spotify: return .green
            case .amazonMusic: return .blue
            case .youtubeMusic: return .red
            }
        }

        var urlScheme: String {
            switch self {
            case .appleMusic: return "music://"
            case .spotify: return "spotify://"
            case .amazonMusic: return "amzn-music://"
            case .youtubeMusic: return "youtube-music://"
            }
        }

        var appStoreURL: String {
            switch self {
            case .appleMusic: return "https://apps.apple.com/app/apple-music/id1108187390"
            case .spotify: return "https://apps.apple.com/app/spotify/id324684580"
            case .amazonMusic: return "https://apps.apple.com/app/amazon-music/id510855668"
            case .youtubeMusic: return "https://apps.apple.com/app/youtube-music/id1017492454"
            }
        }
    }

    // MARK: - Music Track
    struct MusicTrack: Identifiable {
        let id: String
        let title: String
        let artist: String
        let artwork: Image?
        let duration: TimeInterval
    }

    // MARK: - Workout Playlists
    struct WorkoutPlaylist: Identifiable {
        let id: String
        let name: String
        let description: String
        let icon: String
        let genre: String
        let bpm: String

        static let suggestions: [WorkoutPlaylist] = [
            WorkoutPlaylist(
                id: "hiit",
                name: "HIIT Power",
                description: "High-energy tracks for intense intervals",
                icon: "bolt.fill",
                genre: "EDM / Hip-Hop",
                bpm: "140-160"
            ),
            WorkoutPlaylist(
                id: "strength",
                name: "Strength Training",
                description: "Heavy beats for lifting sessions",
                icon: "dumbbell.fill",
                genre: "Rock / Metal",
                bpm: "120-140"
            ),
            WorkoutPlaylist(
                id: "cardio",
                name: "Cardio Flow",
                description: "Upbeat rhythms for running and cycling",
                icon: "figure.run",
                genre: "Pop / Dance",
                bpm: "130-150"
            ),
            WorkoutPlaylist(
                id: "yoga",
                name: "Yoga & Stretch",
                description: "Calm ambient for flexibility work",
                icon: "figure.yoga",
                genre: "Ambient / Chill",
                bpm: "60-80"
            ),
            WorkoutPlaylist(
                id: "warmup",
                name: "Warm Up",
                description: "Building energy for your workout",
                icon: "flame.fill",
                genre: "Various",
                bpm: "100-120"
            ),
            WorkoutPlaylist(
                id: "cooldown",
                name: "Cool Down",
                description: "Wind down after your session",
                icon: "moon.fill",
                genre: "Acoustic / Lo-Fi",
                bpm: "70-90"
            )
        ]
    }

    // MARK: - Initialization
    init() {
        Task {
            await checkAuthorization()
        }
        setupNotifications()
        updateNowPlaying() // Initial fetch
    }

    // MARK: - Polling for Real-Time Updates
    func startPolling() {
        stopPolling()
        updateNowPlaying()
        updatePlaybackState()

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateNowPlaying()
                self?.updatePlaybackState()
                self?.currentPlaybackTime = self?.systemMusicPlayer.currentPlaybackTime ?? 0
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    func refreshNowPlaying() {
        updateNowPlaying()
        updatePlaybackState()
    }

    // MARK: - Authorization
    func checkAuthorization() async {
        authorizationStatus = MusicAuthorization.currentStatus
    }

    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        return status == .authorized
    }

    // MARK: - Playback Control
    func play() {
        if selectedProvider == .appleMusic {
            systemMusicPlayer.play()
        } else {
            openMusicApp()
        }
        isPlaying = true
    }

    func pause() {
        if selectedProvider == .appleMusic {
            systemMusicPlayer.pause()
        }
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func skipToNext() {
        if selectedProvider == .appleMusic {
            systemMusicPlayer.skipToNextItem()
        }
    }

    func skipToPrevious() {
        if selectedProvider == .appleMusic {
            systemMusicPlayer.skipToPreviousItem()
        }
    }

    // MARK: - App Launch
    func openMusicApp() {
        guard let url = URL(string: selectedProvider.urlScheme) else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Open App Store if app not installed
            if let appStoreURL = URL(string: selectedProvider.appStoreURL) {
                UIApplication.shared.open(appStoreURL)
            }
        }
    }

    func openPlaylist(_ playlist: WorkoutPlaylist) {
        // Open music app with search for workout playlist
        let searchQuery = "workout \(playlist.name)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        var urlString: String
        switch selectedProvider {
        case .appleMusic:
            urlString = "music://search?term=\(searchQuery)"
        case .spotify:
            urlString = "spotify:search:\(searchQuery)"
        case .amazonMusic:
            urlString = "amzn-music://search/\(searchQuery)"
        case .youtubeMusic:
            urlString = "youtube-music://search?q=\(searchQuery)"
        }

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            openMusicApp()
        }
    }

    // MARK: - Check App Installation
    func isAppInstalled(_ provider: MusicProvider) -> Bool {
        guard let url = URL(string: provider.urlScheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: systemMusicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }

        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: systemMusicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.updateNowPlaying()
        }

        systemMusicPlayer.beginGeneratingPlaybackNotifications()
    }

    private func updatePlaybackState() {
        isPlaying = systemMusicPlayer.playbackState == .playing
    }

    private func updateNowPlaying() {
        guard let nowPlaying = systemMusicPlayer.nowPlayingItem else {
            currentTrack = nil
            return
        }

        var artwork: Image? = nil
        if let artworkImage = nowPlaying.artwork?.image(at: CGSize(width: 100, height: 100)) {
            artwork = Image(uiImage: artworkImage)
        }

        currentTrack = MusicTrack(
            id: nowPlaying.persistentID.description,
            title: nowPlaying.title ?? "Unknown Track",
            artist: nowPlaying.artist ?? "Unknown Artist",
            artwork: artwork,
            duration: nowPlaying.playbackDuration
        )
    }
}

// MARK: - EQ Animation View
struct EQAnimationView: View {
    @ObservedObject var musicService = MusicService.shared
    let barCount: Int
    let color: Color
    let height: CGFloat

    init(barCount: Int = 4, color: Color = .green, height: CGFloat = 20) {
        self.barCount = barCount
        self.color = color
        self.height = height
    }

    @State private var animationValues: [CGFloat] = []

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: musicService.isPlaying ? (index < animationValues.count ? animationValues[index] : height * 0.3) : height * 0.15)
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.3...0.5))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: musicService.isPlaying
                    )
            }
        }
        .onAppear {
            animationValues = (0..<barCount).map { _ in CGFloat.random(in: height * 0.3...height) }
            startAnimation()
        }
        .onChange(of: musicService.isPlaying) { _, isPlaying in
            if isPlaying {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        guard musicService.isPlaying else { return }
        withAnimation {
            animationValues = (0..<barCount).map { _ in CGFloat.random(in: height * 0.3...height) }
        }
        // Continuously randomize heights while playing
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            guard musicService.isPlaying else {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                animationValues = (0..<barCount).map { _ in CGFloat.random(in: height * 0.3...height) }
            }
        }
    }
}


// MARK: - Music Player Mini View
struct MusicPlayerMiniView: View {
    @ObservedObject var musicService = MusicService.shared
    @State private var showMusicSheet = false

    var body: some View {
        Button {
            showMusicSheet = true
        } label: {
            HStack(spacing: 12) {
                // Artwork or icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(musicService.selectedProvider.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    if let track = musicService.currentTrack, let artwork = track.artwork {
                        artwork
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "music.note")
                            .font(.title3)
                            .foregroundStyle(musicService.selectedProvider.color)
                    }
                }

                // Track info with EQ animation
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(musicService.currentTrack?.title ?? "Not Playing")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        if musicService.isPlaying {
                            EQAnimationView(barCount: 3, color: musicService.selectedProvider.color, height: 14)
                        }
                    }

                    Text(musicService.currentTrack?.artist ?? "Tap to open music")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Play/Pause button
                Button {
                    if musicService.currentTrack != nil {
                        musicService.togglePlayPause()
                    } else {
                        musicService.openMusicApp()
                    }
                } label: {
                    Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(musicService.selectedProvider.color)
                        .frame(width: 44, height: 44)
                        .background(musicService.selectedProvider.color.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .onAppear {
            musicService.startPolling()
        }
        .onDisappear {
            musicService.stopPolling()
        }
        .sheet(isPresented: $showMusicSheet) {
            MusicControlSheet()
                .presentationDetents([.height(580)])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Music Control Sheet
struct MusicControlSheet: View {
    @ObservedObject var musicService = MusicService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and done button
            HStack {
                Text("Music")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)

            // Album artwork with spinning animation when playing
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(musicService.selectedProvider.color.opacity(0.15))
                    .frame(width: 220, height: 220)

                if let track = musicService.currentTrack, let artwork = track.artwork {
                    artwork
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundStyle(musicService.selectedProvider.color)
                }
            }
            .shadow(color: musicService.selectedProvider.color.opacity(0.3), radius: 25, y: 12)
            .scaleEffect(musicService.isPlaying ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: musicService.isPlaying)

            // Track info with EQ animation
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Text(musicService.currentTrack?.title ?? "No Track Playing")
                        .font(.title2)
                        .fontWeight(.bold)

                    if musicService.isPlaying {
                        EQAnimationView(barCount: 4, color: musicService.selectedProvider.color, height: 20)
                    }
                }

                Text(musicService.currentTrack?.artist ?? "Open a music app to start")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            // Playback controls
            HStack(spacing: 44) {
                Button {
                    musicService.skipToPrevious()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundStyle(.primary)
                }

                Button {
                    musicService.togglePlayPause()
                } label: {
                    Image(systemName: musicService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(musicService.selectedProvider.color)
                }

                Button {
                    musicService.skipToNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Open app button
            Button {
                musicService.openMusicApp()
            } label: {
                HStack {
                    Image(systemName: musicService.selectedProvider.icon)
                    Text("Open \(musicService.selectedProvider.rawValue)")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(musicService.selectedProvider.color)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)

            Spacer()

            // Settings hint
            Text("Change music provider in Settings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
        }
        .onAppear {
            musicService.startPolling()
        }
        .onDisappear {
            musicService.stopPolling()
        }
    }
}

struct MusicProviderButton: View {
    let provider: MusicService.MusicProvider
    let isSelected: Bool
    let isInstalled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: provider.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : provider.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white : .primary)

                    if !isInstalled {
                        Text("Not Installed")
                            .font(.caption2)
                            .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? provider.color : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workout Playlist Suggestions View
struct WorkoutPlaylistsView: View {
    @ObservedObject var musicService = MusicService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundStyle(musicService.selectedProvider.color)
                Text("Workout Playlists")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MusicService.WorkoutPlaylist.suggestions) { playlist in
                        WorkoutPlaylistCard(playlist: playlist) {
                            musicService.openPlaylist(playlist)
                        }
                    }
                }
            }
        }
    }
}

struct WorkoutPlaylistCard: View {
    let playlist: MusicService.WorkoutPlaylist
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: playlist.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(playlist.bpm + " BPM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120)
        }
        .buttonStyle(.plain)
    }
}
