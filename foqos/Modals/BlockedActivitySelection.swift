
import Foundation
import SwiftData
import FamilyControls

@Model
class BlockedActivitySelection {
    @Attribute(.unique) var id: String
    var selectedActivity: FamilyActivitySelection
    
    init(id: String = "BlockedActivitySelection", selectedActivity: FamilyActivitySelection = FamilyActivitySelection()) {
        self.id = id
        self.selectedActivity = selectedActivity
    }
    
    static func shared(in context: ModelContext) -> BlockedActivitySelection {
        var descriptor = FetchDescriptor<BlockedActivitySelection>(
            predicate: #Predicate { $0.id == "BlockedActivitySelection" },
            sortBy: [SortDescriptor(\.id)])
        descriptor.fetchLimit = 1
        
        do {
            if let existing = try context.fetch(descriptor).first {
                return existing
            } else {
                let newInstance = BlockedActivitySelection()
                context.insert(newInstance)
                return newInstance
            }
        } catch {
            print("Error fetching BlockedActivitySelection: \(error)")
            let newInstance = BlockedActivitySelection()
            context.insert(newInstance)
            return newInstance
        }
    }
    
    static func updateSelection(in context: ModelContext, with selection: FamilyActivitySelection) {
        let instance = shared(in: context)
        instance.selectedActivity = selection
        try? context.save()
    }
}

