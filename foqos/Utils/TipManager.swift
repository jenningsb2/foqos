import StoreKit

class TipManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private let productID = "dev.ambitionsoftware.2dollartip"
    
    init() {
        // Start listening for transactions immediately
        Task {
            await loadProducts()
            await setupTransactionListener()
        }
    }
    
    @MainActor
    private func setupTransactionListener() async {
        // Handle any pending transactions from previous purchases
        for await result in Transaction.updates {
            do {
                switch result {
                case .verified(let transaction):
                    // Handle successful purchase
                    print("Verified transaction: \(transaction.id)")
                    await transaction.finish()
                case .unverified( _, let error):
                    // Handle unverified transaction
                    print("Unverified transaction: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            self.products = products
            
            // Debug info
            if products.isEmpty {
                print("No products found for ID: \(productID)")
            } else {
                print("Found products: \(products.map { $0.id })")
            }
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
                DispatchQueue.main.async {
                    self.purchasedProductIDs.insert(product.id)
                    print("Purchase success: \(transaction.id)")
                }
                await transaction.finish()
            case .unverified(_, let error):
                print("Purchase unverified: \(error)")
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
