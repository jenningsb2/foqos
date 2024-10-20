import Foundation
import SwiftData

@Model
class BlockedSession {
    @Attribute(.unique) var id: String
    var tag: String
    
    var startTime: Date
    var endTime: Date?
    
    var isActive: Bool {
        return endTime == nil
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    init(tag: String) {
        self.id = UUID().uuidString
        self.tag = tag
        
        self.startTime = Date()
    }
    
    func endSession() {
        self.endTime = Date()
    }
    
    static func mostRecentActiveSession(in context: ModelContext) -> BlockedSession? {
        var descriptor = FetchDescriptor<BlockedSession>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        return try? context.fetch(descriptor).first
    }
    
    static func createSession(in context: ModelContext, withTag tag: String) -> BlockedSession {
        let newSession = BlockedSession(tag: tag)
        context.insert(newSession)
        return newSession
    }
    
    static func recentInactiveSessions(in context: ModelContext, limit: Int = 50) -> [BlockedSession] {
        var descriptor = FetchDescriptor<BlockedSession>(
            predicate: #Predicate { $0.endTime != nil },
            sortBy: [SortDescriptor(\.endTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return (try? context.fetch(descriptor)) ?? []
    }
}
