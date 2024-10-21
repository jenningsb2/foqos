import SwiftUI

struct InactiveBlockedSessionRow: View {
    let session: BlockedSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Label(formattedDuration, systemImage: "clock")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Label(formattedEndTime, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .imageScale(.large)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: session.duration) ?? ""
    }
    
    private var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.endTime ?? Date())
    }
}

#Preview {
    let session = BlockedSession(tag: "Work")
    session.endSession()
    return InactiveBlockedSessionRow(session: session)
}
