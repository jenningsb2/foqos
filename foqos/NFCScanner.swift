import SwiftUI
import CoreNFC

class NFCScanner: NSObject, ObservableObject {
    @Published var scannedNFCTag: String?
    @Published var errorMessage: String?
    @Published var debugLog: String = ""
    private var nfcSession: NFCNDEFReaderSession?
    
    func log(_ message: String) {
        DispatchQueue.main.async {
            print("NFC Debug: \(message)")
            self.debugLog += message + "\n"
        }
    }
    
    func scan() {
        log("Scan method called")
        guard NFCNDEFReaderSession.readingAvailable else {
            log("NFC reading not available on this device")
            self.errorMessage = "NFC scanning not available on this device"
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "Hold your iPhone near an NFC tag."
        log("NFC session created")
        
        do {
            try nfcSession?.begin()
            log("NFC session begun successfully")
        } catch {
            log("Error beginning NFC session: \(error.localizedDescription)")
            self.errorMessage = "Failed to start NFC session: \(error.localizedDescription)"
        }
    }
}

extension NFCScanner: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        log("Session invalidated with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.errorMessage = "NFC session invalidated: \(error.localizedDescription)"
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        log("NDEFs detected: \(messages.count) messages")
        guard let ndefMessage = messages.first,
              let record = ndefMessage.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            log("Failed to read NDEF message")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to read NDEF message"
            }
            return
        }
        
        log("Successfully read NFC tag: \(payload)")
        DispatchQueue.main.async {
            self.scannedNFCTag = payload
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        log("NFC session became active")
    }
}
