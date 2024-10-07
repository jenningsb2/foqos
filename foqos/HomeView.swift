import SwiftUI

struct HomeView: View {
    @StateObject private var appBlocker = AppBlocker()
    @State private var isScanning = false
    @State private var lastScannedTag: String?
    
    var body: some View {
        VStack {
            Text("NFC App Blocker")
                .font(.largeTitle)
            
            if let tag = lastScannedTag {
                Text("Last scanned tag: \(tag)")
                    .padding()
            }
            
            Button("Scan NFC") {
                isScanning = true
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
        .sheet(isPresented: $isScanning) {
            NFCScannerView()
        }
        .onChange(of: lastScannedTag) { _, _ in
            appBlocker.toggleBlocking()
        }
        .onAppear {
            appBlocker.requestAuthorization()
        }
    }
}
