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
        NavigationStack {
            VStack {
                Text("Focus time")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scenePadding()
                    .padding(
                        EdgeInsets(top: -20, leading: 0, bottom: 0, trailing: 0)
                    )
                Spacer()
                Stepper(value: $minutes, in: 0...60, step: 1) {
                    Text("\(minutes) minutes")
                        .font(.caption2)
                }
                .padding(.top, 18)
                .padding(.bottom, 18)
                
                NavigationLink(
                    destination: RemainingMinutesView(timerSeconds: minutes * 60),
                    label: {
                        Text("Confirm")
                    })
            }
            .padding()

        }.onAppear(perform: {
            heartRateMonitor.requestAuthorization()
        })
    }
}

struct ContentView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
        }
    }
}

