import StoreKit

class TipManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private let productID = "dev.ambitionsoftware.2dollartip"
    
    init() {
        Task {
            await loadProducts()
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            self.products = products
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase() async throws {
        guard let product = products.first else {
            print("No products available")
            return
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                await transaction.finish()
                purchasedProductIDs.insert(product.id)
            case .unverified:
                print("Transaction unverified")
            }
        case .userCancelled:
            print("User cancelled")
        case .pending:
            print("Transaction pending")
        @unknown default:
            print("Unknown result")
        }
    }
    
    func tip() {
        Task {
            do {
                try await self.purchase()
            } catch {
                print("Failed to purchase: \(error)")
            }
        }
    }
}
