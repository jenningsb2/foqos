import SwiftUI
import FamilyControls

struct BlockedProfileSelector: View {
    let profile: BlockedProfiles
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    var onTap: () -> Void        // New tap handler
    var onLongPress: () -> Void  // New long press handler
    
    @State private var offset: CGFloat = 0
    @State private var isLongPressing = false  // Track long press state
    private let swipeThreshold: CGFloat = 75
    
    private var cardOpacity: Double {
        let progress = abs(offset) / swipeThreshold
        return max(1 - progress * 0.6, 0.4)
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
        .offset(x: offset)
        .opacity(cardOpacity)
        .scaleEffect(isLongPressing ? 0.95 : 1.0) // Visual feedback for long press
        .animation(.easeInOut(duration: 0.2), value: isLongPressing)
        .gesture(
            // Combine gestures using simultaneousGesture
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
                .simultaneously(with:
                    // Add tap gesture
                    TapGesture()
                        .onEnded {
                            onTap()
                        }
                )
                .simultaneously(with:
                    // Add long press gesture
                    LongPressGesture(minimumDuration: 0.5)
                        .onChanged { isPressing in
                            isLongPressing = isPressing
                        }
                        .onEnded { _ in
                            isLongPressing = false
                            onLongPress()
                        }
                )
        )
    }
}
