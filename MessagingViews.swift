import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Messages Tab
// ─────────────────────────────────────────────
struct MessagesView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var dm = DirectMessagingManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Messages")
                            .font(BRTRFont.largeTitle()).foregroundColor(.white)
                        Spacer()
                    }
                    .padding(20)

                    if dm.isLoading && dm.conversations.isEmpty {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
                            .frame(maxWidth: .infinity).padding(40)
                    } else if dm.conversations.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48)).foregroundColor(.brtrTextMuted)
                            Text("No messages yet")
                                .font(BRTRFont.headline()).foregroundColor(.brtrTextSecondary)
                            Text("Tap 'Send a Message' on any listing to start chatting")
                                .font(BRTRFont.caption()).foregroundColor(.brtrTextMuted)
                                .multilineTextAlignment(.center).padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity).padding(40)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(dm.conversations) { conv in
                                    NavigationLink(destination: DirectChatView(conversation: conv)) {
                                        ConversationRow(conversation: conv)
                                            .environmentObject(authManager)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .task { await dm.fetchConversations() }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Conversation Row
// ─────────────────────────────────────────────
struct ConversationRow: View {
    let conversation: Conversation
    @EnvironmentObject var authManager: AuthManager

    var otherUser: UserProfile? {
        guard let myId = authManager.currentUser?.id else { return nil }
        return conversation.participantOne == myId
            ? conversation.participantTwoUser
            : conversation.participantOneUser
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.brtrPurple)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(otherUser?.fullName.prefix(1) ?? "?"))
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(otherUser?.fullName ?? "Unknown")
                        .font(BRTRFont.headline()).foregroundColor(.white)
                    Text(conversation.lastMessage ?? "No messages yet")
                        .font(.system(size: 13)).foregroundColor(.brtrTextMuted)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundColor(.brtrTextMuted)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider().background(Color.brtrBorder).padding(.leading, 84)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Direct Chat View
// ─────────────────────────────────────────────
struct DirectChatView: View {
    let conversation: Conversation
    // Optional service passed in when opening from a listing
    var service: Service? = nil

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var dm = DirectMessagingManager.shared
    @State private var messageText = ""
    @State private var showListingDetail = false
    @Environment(\.dismiss) var dismiss

    var otherUser: UserProfile? {
        guard let myId = authManager.currentUser?.id else { return nil }
        return conversation.participantOne == myId
            ? conversation.participantTwoUser
            : conversation.participantOneUser
    }

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()
            VStack(spacing: 0) {

                // ── Header ──────────────────────────────────
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Circle()
                        .fill(Color.brtrPurple)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Text(String(otherUser?.fullName.prefix(1) ?? "?"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(otherUser?.fullName ?? "Chat")
                            .font(BRTRFont.headline()).foregroundColor(.white)
                        if let username = otherUser?.username {
                            Text("@\(username)")
                                .font(.system(size: 11)).foregroundColor(.brtrTextMuted)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(Color.brtrCard)

                // ── Listing Context Card ─────────────────────
                if let svc = service {
                    listingContextCard(service: svc)
                }

                // ── Messages ─────────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(dm.messages) { message in
                                let isMe = message.senderId == authManager.currentUser?.id
                                HStack(alignment: .bottom, spacing: 8) {
                                    if isMe { Spacer(minLength: 60) }

                                    if !isMe {
                                        Circle()
                                            .fill(Color.brtrPurpleDim)
                                            .frame(width: 26, height: 26)
                                            .overlay(
                                                Text(String(otherUser?.fullName.prefix(1) ?? "?"))
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(.white)
                                            )
                                    }

                                    VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                                        Text(message.content)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14).padding(.vertical, 10)
                                            .background(isMe ? Color.brtrPurple : Color.brtrCard)
                                            .cornerRadius(18)
                                            .cornerRadius(isMe ? 4 : 18, corners: isMe ? .bottomRight : .bottomLeft)
                                        Text(formatTime(message.createdAt))
                                            .font(.system(size: 10))
                                            .foregroundColor(.brtrTextMuted)
                                            .padding(.horizontal, 4)
                                    }
                                    .id(message.id)

                                    if isMe { Spacer(minLength: 0).frame(width: 0) }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: dm.messages.count) {
                        if let last = dm.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onAppear {
                        if let last = dm.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                // ── Input Bar ────────────────────────────────
                HStack(spacing: 12) {
                    TextField("Message...", text: $messageText)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Color.brtrCard)
                        .cornerRadius(24)

                    Button {
                        let text = messageText.trimmingCharacters(in: .whitespaces)
                        guard !text.isEmpty else { return }
                        messageText = ""
                        Task { await dm.sendMessage(conversationId: conversation.id, content: text) }
                    } label: {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.brtrPurple.opacity(0.4)
                                    : Color.brtrPurple
                            )
                            .clipShape(Circle())
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.brtrCard)
            }
        }
        .navigationBarHidden(true)
        .task {
            await dm.fetchMessages(for: conversation.id)
            await dm.subscribeToMessages(for: conversation.id)
            await dm.markAsRead(conversationId: conversation.id)
        }
        .onDisappear { Task { await dm.unsubscribe() } }
        .sheet(isPresented: $showListingDetail) {
            if let svc = service {
                ServiceDetailView(service: svc)
                    .environmentObject(authManager)
                    .environmentObject(BarterManager.shared)
            }
        }
    }

    // ── Listing Context Card ─────────────────────────────────
    @ViewBuilder
    private func listingContextCard(service: Service) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    if let imageUrl = service.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.brtrPurpleDim
                                .overlay(
                                    Image(systemName: service.serviceCategory.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(.brtrPurpleLight.opacity(0.5))
                                )
                        }
                    } else {
                        Color.brtrPurpleDim
                            .overlay(
                                Image(systemName: service.serviceCategory.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.brtrPurpleLight.opacity(0.5))
                            )
                    }
                }
                .frame(width: 52, height: 52)
                .cornerRadius(10)
                .clipped()

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(service.isProduct ? "Product listing" : "Service listing")
                        .font(.system(size: 11))
                        .foregroundColor(.brtrTextMuted)
                    Text(service.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if let val = service.estimatedValue, !val.isEmpty {
                        Text("$\(val)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.brtrPurpleLight)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // CTA buttons
            HStack(spacing: 10) {
                Button {
                    showListingDetail = true
                } label: {
                    Text("See listing")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.brtrPurple)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    // Pre-fill "Is this still available?"
                    messageText = "Is this still available?"
                } label: {
                    Text("Still available?")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.brtrTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.brtrCard)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brtrBorder, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
        .background(Color.brtrSurface)
        .overlay(
            Rectangle()
                .fill(Color.brtrBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// ─────────────────────────────────────────────
// MARK: - Corner Radius Helper
// ─────────────────────────────────────────────
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// ─────────────────────────────────────────────
// MARK: - Start Chat Sheet (opens from ServiceDetailView)
// ─────────────────────────────────────────────
struct StartChatSheetView: View {
    let service: Service
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var conversation: Conversation?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
                    Text("Opening chat...")
                        .font(BRTRFont.subheadline())
                        .foregroundColor(.brtrTextSecondary)
                }
            } else if let conv = conversation {
                DirectChatView(conversation: conv, service: service)
                    .environmentObject(authManager)
            }
        }
        .task {
            let dm = DirectMessagingManager.shared
            if let convId = await dm.getOrCreateConversation(
                with: service.userId,
                serviceId: service.id
            ) {
                await dm.fetchConversations()
                conversation = dm.conversations.first { $0.id == convId }
                if conversation == nil {
                    conversation = Conversation(
                        id: convId,
                        participantOne: authManager.currentUser!.id,
                        participantTwo: service.userId,
                        serviceId: service.id,
                        lastMessage: nil,
                        lastMessageAt: Date(),
                        createdAt: Date(),
                        participantOneUser: authManager.currentUser,
                        participantTwoUser: service.user
                    )
                }
            }
            isLoading = false
        }
    }
}
