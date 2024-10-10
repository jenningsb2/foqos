import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appBlocker: AppBlocker
    @StateObject private var nfcScanner = NFCScanner()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Time in Focus")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                
                Text("00:00:00")
                    .font(.system(size: 80))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }.padding(.top, 20)
            
            GroupBox {
                WeeklyBarChart()
            } label: {
                Text("Weekly focus time")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }.cornerRadius(10)
            
            GroupBox {
                Section {
                    MenuItem(
                        icon: "hand.raised.fill",
                        iconColor: .red,
                        title: "Apps to block",
                        subtitle: nil,
                        hasDisclosure: true,
                        action: { print("Airplane mode toggled") }
                    )
                    MenuItem(
                        icon: "cart.fill",
                        iconColor: .gray,
                        title: "Purschase NFC tags",
                        subtitle: nil,
                        hasDisclosure: true,
                        action: { print("Airplane mode toggled") }
                    )
                    MenuItem(
                        icon: "heart.fill",
                        iconColor: .green,
                        title: "Donate",
                        subtitle: nil,
                        hasDisclosure: true,
                        action: { print("Airplane mode toggled") }
                    )
                }
            } label: {
                Text("Settings")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }.cornerRadius(10)
            
            
            Spacer()
            ActionButton(title: "Scan to focus") {
                nfcScanner.scan()
            }
        }.padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: nfcScanner.scannedNFCTag) { _, newValue in
            // TODO: do something with the newValue
        }
        .onAppear {
            appBlocker.requestAuthorization()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppBlocker())
}

