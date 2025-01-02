import SwiftUI
import FamilyControls

struct BlockedProfileSelector: View {
    let profile: BlockedProfiles
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    
    @State private var offset: CGFloat = 0
    private let swipeThreshold: CGFloat = 75
    
    // Calculate opacity based on swipe distance
    private var cardOpacity: Double {
        let progress = abs(offset) / swipeThreshold
        return max(1 - progress * 0.6, 0.4) // Limit minimum opacity to 0.4
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.name)
                .font(.headline)
            
            Text("\(BlockedProfiles.countSelectedActivities(profile.selectedActivity)) items blocked")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0)
        )
        .shadow(radius: 2)
        .offset(x: offset)
        .opacity(cardOpacity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.width
                }
                .onEnded { value in
                    if offset < -swipeThreshold {
                        onSwipeLeft()
                    } else if offset > swipeThreshold {
                        onSwipeRight()
                    }
                    offset = 0
                }
        )
    }
}

