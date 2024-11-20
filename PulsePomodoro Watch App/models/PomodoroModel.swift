import Foundation

struct Pomodoro: Codable, Hashable {
    var id: UUID
    var heartRate: Int
    var respiratoryRate: Int
    var startDate: Date
    var endDate: Date
    var duration: Int
    var isHeartRateNormal: Bool
    var isRespirationRateNormal: Bool
    var isCompleted: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(endDate)
        // Combine other properties as needed
    }
    
    // Equality check required by Hashable
    static func ==(lhs: Pomodoro, rhs: Pomodoro) -> Bool {
        return lhs.endDate == rhs.endDate
        // Compare other properties as needed
    }
}

