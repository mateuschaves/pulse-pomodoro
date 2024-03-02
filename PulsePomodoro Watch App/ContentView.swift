//
//  ContentView.swift
//  PulsePomodoro Watch App
//
//  Created by Mateus Henrique on 02/03/24.
//
import WatchKit
import SwiftUI

struct RemainingMinutesView: View {
    var timerSeconds: Int

    @State private var remainingSeconds = 0
    @State private var countdownTimer: Timer?
    @State private var showAlert = false
    
    var body: some View {
        Text("\(self.formatSecondsToMMSS(seconds: remainingSeconds))")
            .font(.largeTitle)
            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            .padding(.bottom, 20)
            .onAppear {
                startCountdown()
            }.alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Time's Up!"),
                    message: Text("Now you can take a moment to relax 🧘"),
                    dismissButton: .default(Text("Ok!"))
                )
            }
    }
    
    func startCountdown() {
        remainingSeconds = timerSeconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                WKInterfaceDevice.current().play(.success)
                timer.invalidate()
                showAlert = true
            }
            NSLog("Segundos restantes: \(self.remainingSeconds)")
        }
    }
    
    func formatSecondsToMMSS(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ContentView: View {
    @State private var minutes = 0
    @State private var showRemainingMinutes = false

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Focus time")
                        .padding()
                        .font(.headline)
                }
                
                Stepper(value: $minutes, in: 0...60, step: 1) {
                    Text("\(minutes) minutes")
                        .font(.headline)
                }
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                
                    NavigationLink(
                        destination: RemainingMinutesView(timerSeconds: minutes * 60),
                        isActive: $showRemainingMinutes,
                        label: {
                            Text("Confirm")
                    })
                }
            }
        }
    }

#Preview {
    ContentView()
}
