import SwiftUI
import CoreNFC

struct NFCResult: Equatable {
    var id: String
    var DateScanned: Date
}

class NFCScanner: NSObject, ObservableObject {
    @Published var scannedNFCTag: NFCResult?
    @Published var isScanning: Bool = false
    @Published var errorMessage: String?
    
    private var nfcSession: NFCReaderSession?
    private var urlToWrite: String?
    private var isWriteMode: Bool = false
    
    func scan() {
        guard NFCReaderSession.readingAvailable else {
            self.errorMessage = "NFC scanning not available on this device"
            return
        }
        
        isWriteMode = false
        nfcSession = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693],
            delegate: self,
            queue: nil
        )
        nfcSession?.alertMessage = "Hold your iPhone near an NFC tag to change focus."
        nfcSession?.begin()
        
        isScanning = true
    }
    
    func writeURL(_ url: String) {
        guard NFCReaderSession.readingAvailable else {
            self.errorMessage = "NFC writing not available on this device"
            return
        }
        
        guard URL(string: url) != nil else {
            self.errorMessage = "Invalid URL format"
            return
        }
        
        isWriteMode = true
        urlToWrite = url
        
        // Using NFCNDEFReaderSession for writing
        let ndefSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        ndefSession.alertMessage = "Hold your iPhone near an NFC tag to write the URL."
        ndefSession.begin()
        
        isScanning = true
    }
}

// Existing NFCTagReaderSessionDelegate
extension NFCScanner: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // This method is called when the session begins.
        return
    }
    
    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.isScanning = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        if tags.count > 1 {
            session.alertMessage = "More than 1 tag detected. Please present only 1 tag."
            return
        }
        
        guard let tag = tags.first else {
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session
                    .invalidate(
                        errorMessage: "Connection error: \(error.localizedDescription)"
                    )
                return
            }
            
            switch tag {
            case .iso7816(let iso7816Tag):
                self.handleISO7816Tag(iso7816Tag, session: session)
            case .feliCa(let feliCaTag):
                self.handleFeliCaTag(feliCaTag, session: session)
            case .iso15693(let iso15693Tag):
                self.handleISO15693Tag(iso15693Tag, session: session)
            case .miFare(let miFareTag):
                self.handleMiFareTag(miFareTag, session: session)
            @unknown default:
                session.invalidate(errorMessage: "Unsupported tag type")
            }
        }
    }
    
    // Existing handler methods remain unchanged...
    private func handleISO7816Tag(
        _ tag: NFCISO7816Tag,
        session: NFCTagReaderSession
    ) {
        // Example: Read AID (Application Identifier)
        let apdu = NFCISO7816APDU(
            instructionClass: 0x00,
            instructionCode: 0xA4,
            p1Parameter: 0x04,
            p2Parameter: 0x00,
            data: Data(),
            expectedResponseLength: -1
        )
        
        tag.sendCommand(apdu: apdu) {
            data,
            sw1,
            sw2,
            error in
            if let error = error {
                session
                    .invalidate(
                        errorMessage: "Error reading ISO7816 tag: \(error.localizedDescription)"
                    )
                return
            }
            
            let result = NFCResult(id: data.hexEncodedString(), DateScanned: Date())
            self.completeScanning(with: result, session: session)
        }
    }
    
    private func handleFeliCaTag(
        _ tag: NFCFeliCaTag,
        session: NFCTagReaderSession
    ) {
        // Example: Read FeliCa System Code
        let systemCode = tag.currentSystemCode.hexEncodedString()
        let result = NFCResult(id: systemCode, DateScanned: Date())
        self.completeScanning(with: result, session: session)
    }
    
    private func handleISO15693Tag(
        _ tag: NFCISO15693Tag,
        session: NFCTagReaderSession
    ) {
        // Example: Read ISO15693 UID
        let uid = tag.identifier.hexEncodedString()
        let result = NFCResult(id: uid, DateScanned: Date())
        self.completeScanning(with: result, session: session)
    }
    
    private func handleMiFareTag(
        _ tag: NFCMiFareTag,
        session: NFCTagReaderSession
    ) {
        // Example: Read MIFARE UID
        let uid = tag.identifier.hexEncodedString()
        let result = NFCResult(id: uid, DateScanned: Date())
        self.completeScanning(with: result, session: session)
    }
    
    private func completeScanning(
        with result: NFCResult,
        session: NFCTagReaderSession
    ) {
        DispatchQueue.main.async {
            self.scannedNFCTag = result
            self.isScanning = false
            session.invalidate()
        }
    }
}

// New NDEF Writing Support
extension NFCScanner: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used for writing
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag found")
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                return
            }
            
            tag.queryNDEFStatus { status, capacity, error in
                guard error == nil else {
                    session.invalidate(errorMessage: "Failed to query tag")
                    return
                }
                
                switch status {
                case .notSupported:
                    session.invalidate(errorMessage: "Tag is not NDEF compliant")
                case .readOnly:
                    session.invalidate(errorMessage: "Tag is read-only")
                case .readWrite:
                    guard let urlString = self.urlToWrite,
                          let url = URL(string: urlString),
                          let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else {
                        session.invalidate(errorMessage: "Invalid URL")
                        return
                    }
                    
                    let message = NFCNDEFMessage(records: [urlPayload])
                    tag.writeNDEF(message) { error in
                        if let error = error {
                            session.invalidate(errorMessage: "Write failed: \(error.localizedDescription)")
                        } else {
                            session.alertMessage = "Successfully wrote URL to tag"
                            session.invalidate()
                        }
                    }
                @unknown default:
                    session.invalidate(errorMessage: "Unknown tag status")
                }
            }
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session became active
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            if let readerError = error as? NFCReaderError {
                switch readerError.code {
                case .readerSessionInvalidationErrorFirstNDEFTagRead,
                     .readerSessionInvalidationErrorUserCanceled:
                    // User canceled or first tag read
                    break
                default:
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhX", $0) }.joined()
    }
}
