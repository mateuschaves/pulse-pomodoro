import WatchKit
import SwiftUI
import Foundation

struct RemainingMinutesView: View {
    var timerSeconds: Int
    
    @State private var remainingSeconds = 0
    @State private var countdownTimer: Timer?
    @State private var isTimeOver = false
    @State private var heartRate = 0
    @State private var startDate = Date()
    @State private var isPaused = false
    @State private var cycles = 0
    @State private var totalTimeFocused = 0
    
    @State private var timeInactiveInSecods = 0
    @State private var startInactiveDate = Date()
    @State private var endInactiveDate = Date()
    
    @EnvironmentObject var router: Router
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        VStack {
            Text("\(self.formatSecondsToMMSS(seconds: remainingSeconds))")
                .font(.largeTitle)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .onAppear {
                    startCountdown()
                }
            HStack {

                Image(systemName: "checkmark")
                    .foregroundStyle(Color.green)
                    .font(.title2)
                    .padding(
                        EdgeInsets(
                            top: 0,
                            leading: 0,
                            bottom: 0,
                            trailing: 26
                        )
                    )
                    .buttonStyle(PlainButtonStyle())
                    .onTapGesture {
                        router.navigate(to: .pomodoroResumeView(timeFocused: totalTimeFocused, startDate: startDate, cycles: cycles))
                    }
                
                Image(systemName: $isPaused.wrappedValue || $isTimeOver.wrappedValue ? "play" : "pause")
                    .foregroundStyle(Color.yellow)
                    .font(.title2)
                    .padding(EdgeInsets(top: 0, leading: 26, bottom: 0, trailing: 0))
                    .onTapGesture(perform: {
                        if (self.isTimeOver) {
                            self.startCountdown()
                            self.isTimeOver.toggle()
                        } else {
                            self.isPaused.toggle()
                        }
                    })
            }
            .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0))
            Spacer()
            Text("\(self.cycles) cycles")
                .padding()
                .fontWeight(Font.Weight.thin)
            
        }.onChange(of: scenePhase)  { newPhase in
            if newPhase == .active {
                self.endInactiveDate = Date()
                self.timeInactiveInSecods = Int(self.endInactiveDate.timeIntervalSince(self.startInactiveDate))
                self.remainingSeconds = max(0, self.remainingSeconds - self.timeInactiveInSecods)
            } else if newPhase == .inactive {
                self.startInactiveDate =  Date()
            }
        }
    }
    
    func handleEndCountdown() {
        WKInterfaceDevice.current().play(.success)
        countdownTimer?.invalidate()
        isTimeOver = true
        self.cycles += 1
        self.totalTimeFocused += timerSeconds
    }
    
    
    func startCountdown() {
        remainingSeconds = timerSeconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.remainingSeconds > 0 {
                if (!self.isPaused) {
                    self.remainingSeconds -= 1
                }
            } else {
                self.handleEndCountdown()
            }
        }
    }
    
    func formatSecondsToMMSS(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct RemainingMinutesView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RemainingMinutesView(timerSeconds: 10)
        }
    }
}

