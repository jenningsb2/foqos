import SwiftUI

struct EmptyView: View {
    let iconName: String
    let headingText: String
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(headingText)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

#Preview {
    EmptyView(iconName: "tray", headingText: "No items in your list")
}
