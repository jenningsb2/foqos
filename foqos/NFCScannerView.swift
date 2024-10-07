import SwiftUI

struct NFCScannerView: View {
    @StateObject private var nfcScanner = NFCScanner()
    
    var body: some View {
        VStack {
            Button("Scan NFC Tag") {
                nfcScanner.scan()
            }
            
            if let scannedTag = nfcScanner.scannedNFCTag {
                Text("Scanned NFC Tag: \(scannedTag)")
            }
            
            if let error = nfcScanner.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
            
            ScrollView {
                Text(nfcScanner.debugLog)
                    .font(.system(size: 12))
                    .padding()
            }
        }
        .onAppear {
            nfcScanner.log("NFCScannerView appeared")
        }
    }
}
