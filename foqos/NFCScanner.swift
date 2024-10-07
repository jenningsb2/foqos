import SwiftUI
import CoreNFC

class NFCScanner: NSObject, ObservableObject {
    @Published var scannedNFCTag: String?
    @Published var isScanning: Bool = false
    @Published var errorMessage: String?
    
    private var nfcSession: NFCNDEFReaderSession?
    
    func scan() {
        guard NFCNDEFReaderSession.readingAvailable else {
            self.errorMessage = "NFC scanning not available on this device"
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold your iPhone near an NFC tag."
        nfcSession?.begin()
        
        isScanning = true
    }
}

extension NFCScanner: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let ndefMessage = messages.first,
              let record = ndefMessage.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to read NDEF message"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.scannedNFCTag = payload
            self.isScanning = false
        }
    }
}
