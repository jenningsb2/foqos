import Foundation
import SwiftData

@Model
final class BlockedSession {
    var tag: String
    
    var startTime: Date
    var endTime: Date?
    
    init(tag: String) {
        self.tag = tag
        
        self.startTime = Date()
    }
    
    func endSession() {
        self.endTime = Date()
    }
    
    func endSession(at date: Date) {
        self.endTime = date
    }
}
