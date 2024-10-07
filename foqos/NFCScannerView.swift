import SwiftUI

struct NFCScannerView: View {
    @Binding var nfcTag: String?
    @StateObject private var nfcScanner = NFCScanner()
    
    var body: some View {
        VStack {
            Button("Scan NFC Tag") {
                nfcScanner.scan()
            }
            
            if let scannedTag = nfcScanner.scannedNFCTag {
                Text("Scanned NFC Tag: \(scannedTag)")
            }
        }
    }
}
