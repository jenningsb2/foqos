import SwiftUI

struct InactiveBlockedSessionView: View {
    let sessions: [BlockedSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Recent Sessions")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                
                List {
                    ForEach(sessions) { session in
                        InactiveBlockedSessionRow(session: session)
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                EdgeInsets(
                                    top: 8,
                                    leading: 0,
                                    bottom: 8,
                                    trailing: 0
                                )
                            )
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }

}

#Preview {
    let session = BlockedSession(tag: "Work")
    session.endSession()
    return InactiveBlockedSessionView(sessions: [session])
}
