
import Foundation
import SwiftData
import FamilyControls

@Model
class BlockedActivitySelection {
    var selectedActivity: FamilyActivitySelection
    
    init(selectedActivity: FamilyActivitySelection) {
        self.selectedActivity = selectedActivity
    }
}
