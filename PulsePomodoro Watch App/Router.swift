import Foundation
import SwiftUI
final class Router: ObservableObject {
    public enum Destination: Codable, Hashable {
        case remainingMinutesView(minutes: Int)
        case pomodoroResumeView(
            timeFocused: Int,
            startDate: Date,
            cycles: Int
        )
        case contentView
    }
    
    @Published var navPath = NavigationPath()
    
    func navigate(to destination: Destination) {
        navPath.append(destination)
    }
    
    func navigateBack() {
        navPath.removeLast()
    }
    
    func navigateToRoot() {
        navPath.removeLast(navPath.count)
    }
}
