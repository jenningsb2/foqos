import SwiftUI
import CoreNFC

class NFCScanner: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var scannedNFCTag: String?
    private var nfcSession: NFCNDEFReaderSession?
    
    func scan() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC scanning not available on this device")
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold your iPhone near an NFC tag."
        nfcSession?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC session invalidated with error: \(error.localizedDescription)")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let ndefMessage = messages.first,
              let record = ndefMessage.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            return
        }
        
        DispatchQueue.main.async {
            self.scannedNFCTag = payload
        }
    }
}
