import Foundation
import Supabase

@MainActor
class MessagingManager: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let shared = MessagingManager()
    private var realtimeChannel: RealtimeChannelV2?
    private init() {}

    // MARK: - Fetch Messages
    func fetchMessages(for barterId: UUID) async {
        isLoading = true
        do {
            let result: [Message] = try await supabase
                .from("messages")
                .select("*, sender:users!sender_id(*)")
                .eq("barter_id", value: barterId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            messages = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Subscribe to Real-time Messages
    func subscribeToMessages(for barterId: UUID) async {
        let channelName = "messages:\(barterId.uuidString)"
        let channel = await supabase.realtimeV2.channel(channelName)

        await channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "barter_id=eq.\(barterId.uuidString)"
        ) { [weak self] action in
            guard let self else { return }
            if let newMessage = try? action.decodeRecord(as: Message.self, decoder: JSONDecoder()) {
                Task { @MainActor in
                    self.messages.append(newMessage)
                }
            }
        }

        do {
            try await channel.subscribe()
            realtimeChannel = channel
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Unsubscribe
    func unsubscribe() async {
        await realtimeChannel?.unsubscribe()
        realtimeChannel = nil
    }

    // MARK: - Send Message
    func sendMessage(barterId: UUID, content: String) async {
        guard let senderId = AuthManager.shared.currentUser?.id else { return }

        struct NewMessage: Encodable {
            let barter_id: String
            let sender_id: String
            let content: String
            let is_read: Bool
        }

        do {
            try await supabase
                .from("messages")
                .insert(NewMessage(
                    barter_id: barterId.uuidString,
                    sender_id: senderId.uuidString,
                    content: content,
                    is_read: false
                ))
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Mark Messages as Read
    func markAsRead(barterId: UUID) async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        struct ReadUpdate: Encodable {
            let is_read: Bool
        }

        do {
            try await supabase
                .from("messages")
                .update(ReadUpdate(is_read: true))
                .eq("barter_id", value: barterId.uuidString)
                .neq("sender_id", value: userId.uuidString)
                .eq("is_read", value: false)
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
