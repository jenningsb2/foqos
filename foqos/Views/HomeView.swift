import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appBlocker: AppBlocker
    
    @State private var lastScannedTag: String?
    @StateObject private var nfcScanner = NFCScanner()
    
    var body: some View {
        VStack {
            Text("NFC App Blocker")
                .font(.largeTitle)
            
            if let tag = lastScannedTag {
                Text("Last scanned tag: \(tag)")
                    .padding()
            }
            
            Button("Scan NFC") {
                nfcScanner.scan()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text("Block Status: \(appBlocker.isBlocking ? "Active" : "Inactive")")
                .font(.headline)
                .padding()
                .foregroundColor(appBlocker.isBlocking ? .red : .green)
            
            Text("Blocked Apps are set in the Apps tab")
                .font(.subheadline)
                .padding(.top)
        }
        .onChange(of: lastScannedTag) { _, _ in
            appBlocker.toggleBlocking()
        }
        .onChange(of: nfcScanner.scannedNFCTag) { oldValue, newValue in
            print("NFC Tag has been scanned with the following value \(newValue)")
        }
        .onAppear {
            appBlocker.requestAuthorization()
        }
    }
}
