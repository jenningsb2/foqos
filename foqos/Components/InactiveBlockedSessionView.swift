import SwiftUI

struct InactiveBlockedSessionView: View {
    let sessions: [BlockedSession]
    
    var body: some View {
        Group {
            if sessions.isEmpty {
                EmptyView(iconName: "checklist.unchecked", headingText: "No recent sessions to display")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                    
                    List(sessions) { session in
                        InactiveBlockedSessionRow(session: session)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
    }
}

#Preview {
    let session = BlockedSession(tag: "Work")
    session.endSession()
    return InactiveBlockedSessionView(sessions: [])
}
