import SwiftUI
import CoreNFC

struct NFCResult: Equatable {
    var id: String
    let data: Data
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
        // Session started
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                return
            }
            
            switch tag {
            case .iso15693(let tag):
                self.readISO15693Tag(tag, session: session)
            case .miFare(let tag):
                self.readMiFareTag(tag, session: session)
            default:
                session.invalidate(errorMessage: "Unsupported tag type")
            }
        }
    }
    
    private func readMiFareTag(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
        let id = tag.identifier.hexEncodedString()
        var tagData = Data()
        
        // Read 12 pages starting from page 4
        func readPage(_ index: Int) {
            guard index < 16 else {
                handleTagData(id: id, data: tagData, session: session)
                return
            }
            
            let command = Data([0x30, UInt8(index)])
            tag.sendMiFareCommand(commandPacket: command) { result in
                switch result {
                case .success(let data):
                    tagData.append(data)
                    readPage(index + 1)
                case .failure:
                    self.handleTagData(id: id, data: tagData, session: session)
                }
            }
        }
        
        readPage(4)
    }
    
    private func readISO15693Tag(_ tag: NFCISO15693Tag, session: NFCTagReaderSession) {
        let id = tag.identifier.hexEncodedString()
        
        tag.readMultipleBlocks(requestFlags: [.address, .highDataRate], blockRange: NSRange(location: 0, length: 4)) { result in
            switch result {
            case .success(let blocks):
                let data = blocks.reduce(Data(), { $0 + $1 })
                self.handleTagData(id: id, data: data, session: session)
            case .failure:
                self.handleTagData(id: id, data: Data(), session: session)
            }
        }
    }
    
    private func handleTagData(id: String, data: Data, session: NFCTagReaderSession) {        
        let result = NFCResult(
            id: id,
            data: data,
            DateScanned: Date()
        )
        
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
