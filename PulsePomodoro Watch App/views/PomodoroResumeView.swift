import Foundation
import SwiftUI

struct PomodoroResumeView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var timeFocused: Int
    var startDate: Date
    var cycles: Int
    
    @State private var averageHr = 0
    @State private var averageBreath = 0
    @State private var goToHome = false
    
    let heartRateMonitor = HeartRateMonitor()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStackLayout {
                    Text("Time focused")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontWeight(Font.Weight.regular)
                        .padding(EdgeInsets(
                            top: 2, leading: 0, bottom: 0, trailing: 0
                        ))
                    Text("\(formatSecondsToMMSS(seconds: timeFocused)) in \(cycles) cycles")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Color.yellow)
                        .fontWeight(Font.Weight.bold)
                    Divider()
                }
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                
                VStackLayout {
                    HStackLayout {
                        VStackLayout {
                            Text("Average HR")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fontWeight(Font.Weight.regular)
                            Text("\(self.averageHr) bpm")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(
                                    Color.red
                                )
                                .fontWeight(Font.Weight.bold)
                        }
                        
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.red)
                            .font(.subheadline)
                            .symbolEffect(
                                .pulse
                            )
                    }
                    
                    Divider()
                }
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                
                VStackLayout {
                    HStackLayout {
                        VStackLayout {
                            Text("Average breaths")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fontWeight(Font.Weight.regular)
                            Text("\(self.averageBreath) per minute")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(
                                    Color.blue
                                )
                                .fontWeight(Font.Weight.bold)
                                .font(.caption2)
                        }
                        
                        Image(systemName: "lungs.fill")
                            .foregroundStyle(Color.blue)
                            .font(.subheadline)
                            .symbolEffect(
                                .pulse
                            )
                    }
                    Divider()
                }
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
            }
            .navigationBarTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            
            .padding()
        }.onAppear(perform: {
            self.savePomodoro()
        })
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    self.goToHome = true
                }) {
                    Image(systemName: "xmark")
                }
            }
        }
        .navigationDestination(
            isPresented: self.$goToHome
        ) {
            ContentView()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden)
    }
    
    func formatSecondsToMMSS(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func savePomodoro() {
        let dispatchGroup = DispatchGroup()
        
        var heartRate: Int?
        var respiratoryRate: Int?
        
        // Enter dispatch group before starting the first asynchronous task
        dispatchGroup.enter()
        heartRateMonitor.getHeartRateFromLastSeconds(seconds: timeFocused) { receivedHeartRate in
            heartRate = receivedHeartRate
            dispatchGroup.leave() // Leave the dispatch group when the first task is done
        }
        
        // Enter dispatch group before starting the second asynchronous task
        dispatchGroup.enter()
        heartRateMonitor.getRespirationRateFromLastSeconds(seconds: timeFocused) { receivedRespiratoryRate in
            respiratoryRate = receivedRespiratoryRate
            dispatchGroup.leave() // Leave the dispatch group when the second task is done
        }
        
        // Notify when both tasks are completed
        dispatchGroup.notify(queue: .main) {
            // Both tasks are finished
            if let heartRate = heartRate, let respiratoryRate = respiratoryRate {
                self.averageHr = heartRate
                self.averageBreath = respiratoryRate
                    
                print("Heart rate on last \(timeFocused) seconds was \(heartRate)")
                let isHeartRateNormal = heartRateMonitor.isRestingHeartRateNormal(heartRate: heartRate)
                
                print("Respiratory rate on last \(timeFocused) seconds was \(respiratoryRate)")
                let isRespirationRateNormal = heartRateMonitor.isRespirationRateNormal(respirationRate: respiratoryRate)
                // Save pomodoro as JSON array
                var previousPomodoros = LocalStorageManager.shared.get(key: "pomodoros") as? [Data] ?? []
                var currentPomodoroJson: Data?
                do {
                    currentPomodoroJson = try JSONEncoder().encode(
                        Pomodoro(
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
                } catch {
                    print("Error encoding current pomodoro: \(error)")
                }
                
                if let currentPomodoroJson = currentPomodoroJson {
                    previousPomodoros.append(currentPomodoroJson)
                    LocalStorageManager.shared.save(key: "pomodoros", value: previousPomodoros)
                }
            }
        }
    }
}

struct PomodoroResumeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PomodoroResumeView(
                timeFocused: 300,
                startDate: Date(),
                cycles: 2
            )
        }
    }
}
