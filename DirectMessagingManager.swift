import Foundation
import Supabase

// MARK: - Conversation Model

struct Conversation: Codable, Identifiable {
    let id: UUID
    var participantOne: UUID
    var participantTwo: UUID
    var serviceId: UUID?
    var serviceTitle: String?
    var lastMessage: String?
    var lastMessageAt: Date
    var createdAt: Date
    var participantOneUser: UserProfile?
    var participantTwoUser: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case participantOne = "participant_one"
        case participantTwo = "participant_two"
        case serviceId = "service_id"
        case serviceTitle = "service_title"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
        case participantOneUser = "participant_one_user"
        case participantTwoUser = "participant_two_user"
    }
}

// MARK: - Direct Message Model

struct DirectMessage: Codable, Identifiable {
    let id: UUID
    var conversationId: UUID
    var senderId: UUID
    var content: String
    var isRead: Bool
    var createdAt: Date
    var sender: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case isRead = "is_read"
        case createdAt = "created_at"
        case sender
    }
}

// MARK: - DirectMessagingManager

@MainActor
class DirectMessagingManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [DirectMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let shared = DirectMessagingManager()
    private var realtimeChannel: RealtimeChannelV2?
    private init() {}

    // MARK: - Fetch or Create Conversation (per listing)

    func getOrCreateConversation(with otherUserId: UUID, serviceId: UUID? = nil) async -> UUID? {
        guard let myId = AuthManager.shared.currentUser?.id else { return nil }

        do {
            if let serviceId = serviceId {
                // Per-listing: find exact match on both participants + service_id
                let existing1: [Conversation] = try await supabase
                    .from("conversations")
                    .select()
                    .eq("participant_one", value: myId.uuidString)
                    .eq("participant_two", value: otherUserId.uuidString)
                    .eq("service_id", value: serviceId.uuidString)
                    .limit(1)
                    .execute()
                    .value
                if let conv = existing1.first { return conv.id }

                let existing2: [Conversation] = try await supabase
                    .from("conversations")
                    .select()
                    .eq("participant_one", value: otherUserId.uuidString)
                    .eq("participant_two", value: myId.uuidString)
                    .eq("service_id", value: serviceId.uuidString)
                    .limit(1)
                    .execute()
                    .value
                if let conv = existing2.first { return conv.id }
            } else {
                // No service: find any conversation between these two users
                let existing1: [Conversation] = try await supabase
                    .from("conversations")
                    .select()
                    .eq("participant_one", value: myId.uuidString)
                    .eq("participant_two", value: otherUserId.uuidString)
                    .limit(1)
                    .execute()
                    .value
                if let conv = existing1.first { return conv.id }

                let existing2: [Conversation] = try await supabase
                    .from("conversations")
                    .select()
                    .eq("participant_one", value: otherUserId.uuidString)
                    .eq("participant_two", value: myId.uuidString)
                    .limit(1)
                    .execute()
                    .value
                if let conv = existing2.first { return conv.id }
            }

            // Create new conversation
            struct NewConversation: Encodable {
                let participant_one: String
                let participant_two: String
                let service_id: String?
                let service_title: String?
            }

            // Fetch service title if we have a serviceId
            var title: String? = nil
            if let sid = serviceId {
                title = await fetchService(id: sid)?.title
            }

            let created: [Conversation] = try await supabase
                .from("conversations")
                .insert(NewConversation(
                    participant_one: myId.uuidString,
                    participant_two: otherUserId.uuidString,
                    service_id: serviceId?.uuidString,
                    service_title: title
                ))
                .select()
                .execute()
                .value

            return created.first?.id

        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Fetch All Conversations

    func fetchConversations() async {
        guard let myId = AuthManager.shared.currentUser?.id else { return }
        isLoading = true

        do {
            let asOne: [Conversation] = try await supabase
                .from("conversations")
                .select("""
                    *,
                    participant_one_user:users!participant_one(*),
                    participant_two_user:users!participant_two(*)
                """)
                .eq("participant_one", value: myId.uuidString)
                .order("last_message_at", ascending: false)
                .execute()
                .value

            let asTwo: [Conversation] = try await supabase
                .from("conversations")
                .select("""
                    *,
                    participant_one_user:users!participant_one(*),
                    participant_two_user:users!participant_two(*)
                """)
                .eq("participant_two", value: myId.uuidString)
                .order("last_message_at", ascending: false)
                .execute()
                .value

            conversations = (asOne + asTwo).sorted { $0.lastMessageAt > $1.lastMessageAt }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Fetch Messages

    func fetchMessages(for conversationId: UUID) async {
        isLoading = true
        do {
            let result: [DirectMessage] = try await supabase
                .from("direct_messages")
                .select("*, sender:users!sender_id(*)")
                .eq("conversation_id", value: conversationId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            messages = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Send Message

    func sendMessage(conversationId: UUID, content: String) async {
        guard let senderId = AuthManager.shared.currentUser?.id else { return }

        struct NewMessage: Encodable {
            let conversation_id: String
            let sender_id: String
            let content: String
            let is_read: Bool
        }

        do {
            try await supabase
                .from("direct_messages")
                .insert(NewMessage(
                    conversation_id: conversationId.uuidString,
                    sender_id: senderId.uuidString,
                    content: content,
                    is_read: false
                ))
                .execute()

            try await supabase
                .from("conversations")
                .update(["last_message": content, "last_message_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: conversationId.uuidString)
                .execute()

            await fetchMessages(for: conversationId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Fetch a Single Service

    func fetchService(id: UUID) async -> Service? {
        do {
            let result: [Service] = try await supabase
                .from("services")
                .select("*, users(*)")
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value
            return result.first
        } catch {
            return nil
        }
    }

    // MARK: - Subscribe to Real-time

    func subscribeToMessages(for conversationId: UUID) async {
        let channel = await supabase.realtimeV2.channel("direct_messages:\(conversationId.uuidString)")

        await channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "direct_messages",
            filter: "conversation_id=eq.\(conversationId.uuidString)"
        ) { [weak self] action in
            guard let self else { return }
            if let msg = try? action.decodeRecord(as: DirectMessage.self, decoder: JSONDecoder()) {
                Task { @MainActor in
                    if !self.messages.contains(where: { $0.id == msg.id }) {
                        self.messages.append(msg)
                    }
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

    // MARK: - Mark as Read

    func markAsRead(conversationId: UUID) async {
        guard let myId = AuthManager.shared.currentUser?.id else { return }
        do {
            try await supabase
                .from("direct_messages")
                .update(["is_read": true])
                .eq("conversation_id", value: conversationId.uuidString)
                .neq("sender_id", value: myId.uuidString)
                .eq("is_read", value: false)
                .execute()
        } catch {}
    }
}
