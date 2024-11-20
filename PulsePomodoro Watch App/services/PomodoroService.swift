import Foundation

class PomodoroService {
    static let shared = PomodoroService()
    
    func savePomodoroOnStorage(
        heartRate: Int,
        respiratoryRate: Int,
        startDate: Date,
        timeFocused: Int,
        isHeartRateNormal: Bool,
        isRespirationRateNormal: Bool,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        var previousPomodoros = LocalStorageManager.shared.get(key: "pomodoros") as? [Data] ?? []
                var currentPomodoroJson: Data?
                do {
                    currentPomodoroJson = try JSONEncoder().encode(
                        Pomodoro(
                            id: UUID(),
                            heartRate: heartRate,
                            respiratoryRate: respiratoryRate,
                            startDate: startDate,
                            endDate: Date(),
                            duration: timeFocused,
                            isHeartRateNormal: isHeartRateNormal,
                            isRespirationRateNormal: isRespirationRateNormal,
                            isCompleted: true
                        )
                    )
                    if let currentPomodoroJson = currentPomodoroJson {
                        previousPomodoros.append(currentPomodoroJson)
                        LocalStorageManager.shared.save(key: "pomodoros", value: previousPomodoros)
                    }

                    completion(.success(true))
                } catch {
                    completion(.failure(error))
                    print("Error encoding current pomodoro: \(error)")
                }
                
    }
    
    func fetchPomodoro(
        completion: @escaping (Result<[Pomodoro], Error>) -> Void
    ) {
        let pomodoros = LocalStorageManager.shared.get(key: "pomodoros") as? [Data] ?? []
        var decodedPomodoros: [Pomodoro] = []
        
        for pomodoro in pomodoros {
            do {
                let decodedPomodoro = try JSONDecoder().decode(Pomodoro.self, from: pomodoro)
                decodedPomodoros.append(decodedPomodoro)
            } catch {
                completion(.failure(error))
                print("Error decoding pomodoro: \(error)")
            }
        }
        
        completion(.success(decodedPomodoros))
    }
}
