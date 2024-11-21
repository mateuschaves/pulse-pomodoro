import WatchKit
import SwiftUI
import UIKit
import UserNotifications

struct ContentView: View {
    @State private var minutes = 0
    @State private var showRemainingMinutes = false
    @State private var heartRateToShow = 0
    @State private var pomodoros: [Pomodoro] = []
    @EnvironmentObject var router: Router
    
    
    let timerOptionsInMinutes: [Int] = [1, 2, 3, 4, 5, 10, 15, 20, 30, 45, 60]
    
    var columns: [GridItem] = [
        GridItem(.fixed(80)),
        GridItem(.fixed(80))
    ]
    
    var columnsPomodoroList: [GridItem] = [
        GridItem(.fixed(200))
    ]
    
    let heartRateMonitor = HeartRateMonitor()
    let pomodoroService = PomodoroService()
    
    var body: some View {
        TabView {
            VStack {
                Text("All timers")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scenePadding()
                    .padding(
                        EdgeInsets(top: -20, leading: 0, bottom: 0, trailing: 0)
                    )
                Spacer()
                ScrollView {
                    LazyVGrid(columns: self.columns) {
                        ForEach(timerOptionsInMinutes, id: \.self) {timerOptionsInMinutes in
                            
                            TimerOptionComponent(valueInMin: timerOptionsInMinutes).onTapGesture {
                                router.navigate(to: .remainingMinutesView(
                                    minutes: timerOptionsInMinutes * 60
                                ))
                            }
                        }
                    }
                }
            }
            VStack {
                Text("Pomodoros")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                        ForEach(pomodoros, id: \.self) {pomodoro in
                            VStack(alignment: .leading) {
                                Text("Duration: \(formatSecondsToMMSS(seconds: pomodoro.duration))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                    
                                HStack {
                                    Image(systemName: "lungs.fill")
                                        .foregroundStyle(Color.blue)
                                        .font(.system(size: 12))
                                    Text("\(pomodoro.respiratoryRate)")
                                        .font(.system(size: 10))
        
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(Color.red)
                                        .font(.system(size: 12))
                                    Text("\(pomodoro.heartRate)")
                                        .font(.system(size: 10))
                                }
                                .padding(.vertical, 4)
                                
                                
                                Text(formatRelativeTime(from: pomodoro.endDate))
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                
                                Divider()
                            }
                            .padding(.all, 4)
                        }
                }
            }.onAppear(perform: {
                pomodoroService.fetchPomodoro { (result: Result<[Pomodoro], Error>) in
                    switch result {
                    case .success(let pomodoros):
                        // Successfully fetched pomodoros, update the state
                        self.pomodoros = pomodoros.sorted { $0.endDate > $1.endDate }
                    case .failure(let error):
                        // Handle the error (e.g., show an alert or log it)
                        print("Error fetching pomodoros: \(error)")
                    }
                }
            })
        }.onAppear(perform: {
            heartRateMonitor.requestAuthorization()
        })
        .navigationBarBackButtonHidden(true)
    }
}

struct ContentView_Preview: PreviewProvider {
    
    @State private var pomodoros: [Pomodoro] = []
    static var previews: some View {
        NavigationStack {
            ContentView()
        }
    }
}

