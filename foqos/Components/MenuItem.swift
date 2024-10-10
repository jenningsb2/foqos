import SwiftUI

struct MenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let hasDisclosure: Bool
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 29, height: 29)
                    .background(iconColor)
                    .cornerRadius(6)
                
                VStack(alignment: .leading) {
                    Text(title)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if hasDisclosure {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 5)
    }
}
