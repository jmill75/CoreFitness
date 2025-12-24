import SwiftUI

@main
struct CoreFitnessWatchApp: App {

    @StateObject private var connectivityManager = WatchPhoneConnectivityManager()
    @StateObject private var workoutState = WatchWorkoutState()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(connectivityManager)
                .environmentObject(workoutState)
        }
    }
}
