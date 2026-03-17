import Foundation
import Supabase

@MainActor
class BarterManager: ObservableObject {
    @Published var incomingRequests: [BarterRequest] = []
    @Published var outgoingRequests: [BarterRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let shared = BarterManager()
    private init() {}

    // MARK: - Fetch Requests
    func fetchRequests() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        isLoading = true
        do {
            let incoming: [BarterRequest] = try await supabase
                .from("barter_requests")
                .select("""
                    *,
                    from_user:users!from_user_id(*),
                    to_user:users!to_user_id(*),
                    offered_service:services!offered_service_id(*),
                    requested_service:services!requested_service_id(*)
                """)
                .eq("to_user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            incomingRequests = incoming

            let outgoing: [BarterRequest] = try await supabase
                .from("barter_requests")
                .select("""
                    *,
                    from_user:users!from_user_id(*),
                    to_user:users!to_user_id(*),
                    offered_service:services!offered_service_id(*),
                    requested_service:services!requested_service_id(*)
                """)
                .eq("from_user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            outgoingRequests = outgoing
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Send Barter Request
    func sendRequest(
        toUserId: UUID,
        offeredServiceId: UUID,
        requestedServiceId: UUID,
        message: String
    ) async {
        guard let fromUserId = AuthManager.shared.currentUser?.id else { return }
        isLoading = true
        do {
            let request: [String: String] = [
                "from_user_id": fromUserId.uuidString,
                "to_user_id": toUserId.uuidString,
                "offered_service_id": offeredServiceId.uuidString,
                "requested_service_id": requestedServiceId.uuidString,
                "status": "pending",
                "message": message
            ]
            try await supabase
                .from("barter_requests")
                .insert(request)
                .execute()
            await fetchRequests()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Update Request Status
    func updateStatus(requestId: UUID, status: BarterStatus) async {
        do {
            try await supabase
                .from("barter_requests")
                .update(["status": status.rawValue])
                .eq("id", value: requestId.uuidString)
                .execute()
            await fetchRequests()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
