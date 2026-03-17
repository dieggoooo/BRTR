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
                .order("created_at", ascending: false)
            
            // Apply filters on the server side when possible
            if let category = category, category != "All" {
                query = query.eq("category", value: category)
            }
            if let search = searchQuery, !search.isEmpty {
                query = query.ilike("title", value: "%\(search)%")
            }
            
            let result: [Service] = try await query.execute().value
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

    // MARK: - Create Service
    func createService(
        title: String,
        description: String,
        category: String,
        imageData: Data? = nil
    ) async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        do {
            var imageUrl: String? = nil

            // Upload image if provided
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
            }

            try await supabase
                .from("services")
                .insert(NewService(
                    user_id: userId.uuidString,
                    title: title,
                    description: description,
                    category: category,
                    image_url: imageUrl,
                    is_active: true
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
