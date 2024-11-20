import SwiftUI

struct TimerOptionComponent: View {
    let valueInMin: Int
    
    init(valueInMin: Int) {
        self.valueInMin = valueInMin
    }
    
    var body: some View {
        VStack {
            Text(String(valueInMin))
                .bold()
                .font(.system(size: 18, weight: .bold))
            Text("MIN")
                .font(.system(size: 12))
                .foregroundColor(.orange)
        }
        .frame(width: 70, height: 70, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 180, style: .continuous)
                .fill(Color.gray.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 180)
                .stroke(Color.orange, lineWidth: 2)
        )
    }
}

#Preview {
    TimerOptionComponent(valueInMin: 1)
}
