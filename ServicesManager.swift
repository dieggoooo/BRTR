import Foundation
import Supabase

@MainActor
class ServicesManager: ObservableObject {
    @Published var services: [Service] = []
    @Published var myServices: [Service] = []
    @Published var savedListingIds: Set<UUID> = []
    @Published var savedListings: [Service] = []
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

            self.services = result
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Fetch My Services

    func fetchMyServices() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        do {
            let result: [Service] = try await supabase
                .from("services")
                .select("*, users(*)")
                .eq("user_id", value: userId.uuidString)
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value
            self.myServices = result
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create Service

    func createService(
        title: String,
        description: String,
        category: String,
        imageData: Data?,
        listingType: String?,
        estimatedValue: String?,
        seekingInReturn: String?,
        tradeFlexibility: Int?,
        exchangeOptions: [String]?,
        zipCode: String?,
        barterRangeMin: Int?,
        barterRangeMax: Int?,
        condition: String?,
        brand: String?,
        modelYear: String?,
        weightLbs: String?,
        dimensions: String?,
        deliveryMethods: [String]?,
        hasOriginalBox: Bool?,
        hasReceipt: Bool?,
        hasSerialNumber: Bool?,
        scope: String?,
        serviceMode: String?,
        experienceLevel: String?,
        availableDays: [String]?,
        portfolioLink: String?,
        materialsNote: String?
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            guard let userId = try? await supabase.auth.session.user.id else {
                errorMessage = "Not authenticated"
                isLoading = false
                return
            }

            var imageUrl: String? = nil
            if let imageData = imageData {
                let fileName = "\(UUID().uuidString).jpg"
                let path = "\(userId.uuidString)/\(fileName)"
                try await supabase.storage
                    .from("service-images")
                    .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
                let publicUrl = try supabase.storage
                    .from("service-images")
                    .getPublicURL(path: path)
                imageUrl = publicUrl.absoluteString
            }

            struct NewService: Encodable {
                let user_id: String
                let title: String
                let description: String
                let category: String
                let image_url: String?
                let is_active: Bool
                let listing_type: String?
                let estimated_value: String?
                let seeking_in_return: String?
                let trade_flexibility: Int?
                let exchange_options: [String]?
                let zip_code: String?
                let barter_range_min: Int?
                let barter_range_max: Int?
                let condition: String?
                let brand: String?
                let model_year: String?
                let weight_lbs: String?
                let dimensions: String?
                let delivery_methods: [String]?
                let has_original_box: Bool?
                let has_receipt: Bool?
                let has_serial_number: Bool?
                let scope: String?
                let service_mode: String?
                let experience_level: String?
                let available_days: [String]?
                let portfolio_link: String?
                let materials_note: String?
            }

            let newService = NewService(
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
            )

            try await supabase
                .from("services")
                .insert(newService)
                .execute()

            await fetchServices()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Saved Listings

    func fetchSavedListings() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        do {
            struct SavedRow: Decodable {
                let service_id: UUID
            }
            let rows: [SavedRow] = try await supabase
                .from("saved_listings")
                .select("service_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            self.savedListingIds = Set(rows.map { $0.service_id })

            if !savedListingIds.isEmpty {
                let ids = savedListingIds.map { $0.uuidString }
                let saved: [Service] = try await supabase
                    .from("services")
                    .select("*, users(*)")
                    .in("id", values: ids)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                self.savedListings = saved
            } else {
                self.savedListings = []
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func saveListing(_ serviceId: UUID) async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        do {
            struct SaveInsert: Encodable {
                let user_id: String
                let service_id: String
            }
            try await supabase
                .from("saved_listings")
                .insert(SaveInsert(user_id: userId.uuidString, service_id: serviceId.uuidString))
                .execute()
            savedListingIds.insert(serviceId)
            await fetchSavedListings()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func unsaveListing(_ serviceId: UUID) async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        do {
            try await supabase
                .from("saved_listings")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("service_id", value: serviceId.uuidString)
                .execute()
            savedListingIds.remove(serviceId)
            savedListings.removeAll { $0.id == serviceId }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func toggleSave(_ serviceId: UUID) async {
        if savedListingIds.contains(serviceId) {
            await unsaveListing(serviceId)
        } else {
            await saveListing(serviceId)
        }
    }
}
