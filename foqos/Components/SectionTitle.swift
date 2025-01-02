import SwiftUI

struct SectionTitle: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.regular)
            .foregroundColor(.secondary)
    }
}

// Preview
struct SectionTitle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SectionTitle("Weekly Usage")
            SectionTitle("Monthly Stats")
            SectionTitle("Annual Report")
        }
        .padding()
    }
}
