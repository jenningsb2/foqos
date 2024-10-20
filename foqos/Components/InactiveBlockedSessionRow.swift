import SwiftUI

struct InactiveBlockedSessionRow: View {
    let session: BlockedSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.tag)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Label(formattedDuration, systemImage: "clock")
                Spacer()
                Label(formattedEndTime, systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: session.duration) ?? ""
    }
    
    private var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: session.endTime ?? Date())
    }
}

#Preview {
    let session = BlockedSession(tag: "Work")
    session.endSession()
    return InactiveBlockedSessionRow(session: session)
}
