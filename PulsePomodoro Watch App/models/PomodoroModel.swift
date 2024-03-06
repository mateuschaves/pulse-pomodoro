import Foundation

struct Pomodoro: Codable {
    var heartRate: Int
    var respiratoryRate: Int
    var startDate: Date
    var endDate: Date
    var duration: Int
    var isHeartRateNormal: Bool
    var isRespirationRateNormal: Bool
    var isCompleted: Bool
}

