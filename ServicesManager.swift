import Foundation
import Supabase

@MainActor
class ServicesManager: ObservableObject {
    @Published var services: [Service] = []
    @Published var myServices: [Service] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let shared = ServicesManager()
    private init() {}

    // MARK: - Fetch All Services
    func fetchServices(category: String? = nil, searchQuery: String? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            var query = supabase
                .from("services")
                .select("*, users(*)")
                .eq("is_active", value: true)

            if let category = category, category != "All" {
                query = query.eq("category", value: category)
            }
            if let search = searchQuery, !search.isEmpty {
                query = query.ilike("title", value: "%\(search)%")
            }

            let result: [Service] = try await query
                .order("created_at", ascending: false)
                .execute()
                .value
            services = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Fetch My Services
    func fetchMyServices() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        do {
            let result: [Service] = try await supabase
                .from("services")
                .select("*, users(*)")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            myServices = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create Service (full fields)
    func createService(
        title: String,
        description: String,
        category: String,
        imageData: Data? = nil,
        listingType: String = "service",
        estimatedValue: String? = nil,
        seekingInReturn: String? = nil,
        tradeFlexibility: Int = 65,
        exchangeOptions: [String] = [],
        zipCode: String? = nil,
        barterRangeMin: Int = 5,
        barterRangeMax: Int = 75,
        // Product
        condition: String? = nil,
        brand: String? = nil,
        modelYear: String? = nil,
        weightLbs: String? = nil,
        dimensions: String? = nil,
        deliveryMethods: [String] = [],
        hasOriginalBox: Bool = false,
        hasReceipt: Bool = false,
        hasSerialNumber: Bool = false,
        // Service
        scope: String? = nil,
        serviceMode: String? = nil,
        experienceLevel: String? = nil,
        availableDays: [String] = [],
        portfolioLink: String? = nil,
        materialsNote: String? = nil
    ) async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil

        do {
            var imageUrl: String? = nil
            if let data = imageData {
                let fileName = "\(userId.uuidString)/\(UUID().uuidString).jpg"
                try await supabase.storage
                    .from("service-images")
                    .upload(path: fileName, file: data, options: .init(contentType: "image/jpeg"))
                imageUrl = try supabase.storage
                    .from("service-images")
                    .getPublicURL(path: fileName)
                    .absoluteString
            }

            struct NewService: Encodable {
                let user_id: String
                let title: String
                let description: String
                let category: String
                let image_url: String?
                let is_active: Bool
                let listing_type: String
                let estimated_value: String?
                let seeking_in_return: String?
                let trade_flexibility: Int
                let exchange_options: [String]
                let zip_code: String?
                let barter_range_min: Int
                let barter_range_max: Int
                let condition: String?
                let brand: String?
                let model_year: String?
                let weight_lbs: String?
                let dimensions: String?
                let delivery_methods: [String]
                let has_original_box: Bool
                let has_receipt: Bool
                let has_serial_number: Bool
                let scope: String?
                let service_mode: String?
                let experience_level: String?
                let available_days: [String]
                let portfolio_link: String?
                let materials_note: String?
            }

            try await supabase
                .from("services")
                .insert(NewService(
                    user_id: userId.uuidString,
                    title: title,
                    description: description,
                    category: category,
                    image_url: imageUrl,
                    is_active: true,
                    listing_type: listingType,
                    estimated_value: estimatedValue,
                    seeking_in_return: seekingInReturn,
                    trade_flexibility: tradeFlexibility,
                    exchange_options: exchangeOptions,
                    zip_code: zipCode,
                    barter_range_min: barterRangeMin,
                    barter_range_max: barterRangeMax,
                    condition: condition,
                    brand: brand,
                    model_year: modelYear,
                    weight_lbs: weightLbs,
                    dimensions: dimensions,
                    delivery_methods: deliveryMethods,
                    has_original_box: hasOriginalBox,
                    has_receipt: hasReceipt,
                    has_serial_number: hasSerialNumber,
                    scope: scope,
                    service_mode: serviceMode,
                    experience_level: experienceLevel,
                    available_days: availableDays,
                    portfolio_link: portfolioLink,
                    materials_note: materialsNote
                ))
                .execute()

            await fetchMyServices()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Delete Service
    func deleteService(id: UUID) async {
        errorMessage = nil
        do {
            try await supabase
                .from("services")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            myServices.removeAll { $0.id == id }
            services.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Fetch Services by User
    func fetchServices(for userId: UUID) async -> [Service] {
        do {
            let result: [Service] = try await supabase
                .from("services")
                .select("*, users(*)")
                .eq("user_id", value: userId.uuidString)
                .eq("is_active", value: true)
                .execute()
                .value
            return result
        } catch {
            return []
        }
    }
}
