//
//  ContentView.swift
//  PulsePomodoro Watch App
//
//  Created by Mateus Henrique on 02/03/24.
//
import WatchKit
import SwiftUI
import UIKit
import UserNotifications

struct ContentView: View {
    @State private var minutes = 0
    @State private var showRemainingMinutes = false
    @State private var heartRateToShow = 0
    
    let heartRateMonitor = HeartRateMonitor()
    
    var body: some View {
        NavigationView {
            VStack {
                Stepper(value: $minutes, in: 0...60, step: 1) {
                    Text("\(minutes) minutes")
                        .font(.headline)
                }
                .padding(.top, 18)
                .padding(.bottom, 18)
                
                NavigationLink(
                    destination: RemainingMinutesView(timerSeconds: minutes * 60),
                    label: {
                        Text("Confirm")
                    })
            }.navigationTitle("Focus time")
        }.onAppear(perform: {
            heartRateMonitor.requestAuthorization()
        })
    }
}


