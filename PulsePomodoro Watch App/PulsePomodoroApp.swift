import SwiftUI

@main
struct PulsePomodoro_Watch_AppApp: App {
    @ObservedObject var router = Router()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.navPath) {
                ContentView()
                    .navigationDestination(for: Router.Destination.self) { destination in
                        switch destination {
                        case .remainingMinutesView(let minutes):
                            RemainingMinutesView(timerSeconds: minutes);
                        case .pomodoroResumeView(let timeFocused, let startDate, let cycles):
                            PomodoroResumeView(
                                timeFocused: timeFocused,
                                startDate: startDate,
                                cycles: cycles
                            );
                        case .contentView:
                            ContentView();
                        }
                    }
            }.environmentObject(router)
        }
    }
}
