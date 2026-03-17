import SwiftUI

struct ServiceDetailView: View {
    let service: Service
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var barterManager: BarterManager

    @State private var showProposeSheet = false
    @State private var showMessageSheet = false
    @State private var isOwnService = false

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Hero image
                    ZStack {
                        if let imageUrl = service.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                heroPlaceholder
                            }
                            .frame(height: 280)
                            .clipped()
                        } else {
                            heroPlaceholder
                                .frame(height: 280)
                        }
                    }

                    VStack(alignment: .leading, spacing: 24) {

                        // Title block
                        VStack(alignment: .leading, spacing: 8) {
                            Text(service.serviceCategory.rawValue.uppercased())
                                .font(BRTRFont.caption())
                                .foregroundColor(.brtrPurpleLight)
                                .tracking(1.5)

                            Text(service.title)
                                .font(BRTRFont.largeTitle())
                                .foregroundColor(.white)

                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .foregroundColor(.brtrTextMuted)
                                Text(service.availability)
                                    .font(BRTRFont.subheadline())
                                    .foregroundColor(.brtrTextSecondary)
                                Text("·")
                                    .foregroundColor(.brtrTextMuted)
                                Text(service.estimatedValue)
                                    .font(BRTRFont.subheadline())
                                    .foregroundColor(.brtrPurpleLight)
                            }
                        }

                        Divider().background(Color.brtrBorder)

                        // Owner card
                        HStack(spacing: 16) {
                            if let avatarUrl = service.owner.avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    avatarPlaceholder
                                }
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                            } else {
                                avatarPlaceholder
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(service.owner.fullName)
                                        .font(BRTRFont.headline())
                                        .foregroundColor(.white)
                                    if service.owner.isVerified {
                                        VerifiedBadge()
                                    }
                                }
                                HStack(spacing: 4) {
                                    StarRating(rating: service.owner.rating)
                                    if service.owner.reviewCount > 0 {
                                        Text("(\(service.owner.reviewCount))")
                                            .font(BRTRFont.caption())
                                            .foregroundColor(.brtrTextMuted)
                                    }
                                }
                            }

                            Spacer()

                            if !isOwnService {
                                Text("View Profile")
                                    .font(BRTRFont.caption())
                                    .foregroundColor(.brtrPurpleLight)
                            }
                        }
                        .padding(16)
                        .brtrCard()

                        // Description
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About this service")
                                .font(BRTRFont.title2())
                                .foregroundColor(.white)
                            Text(service.description)
                                .font(BRTRFont.body())
                                .foregroundColor(.brtrTextSecondary)
                        }

                        // Stats row
                        HStack(spacing: 12) {
                            StatPill(icon: "star.fill", value: String(format: "%.1f", service.owner.rating), label: "Rating", color: .yellow)
                            StatPill(icon: "arrow.2.squarepath", value: "\(service.owner.completedTrades)", label: "Trades", color: .brtrPurpleLight)
                            StatPill(icon: "checkmark.seal.fill", value: service.owner.isVerified ? "Yes" : "No", label: "Verified", color: .brtrGreen)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 120)
                }
            }

            // Bottom CTA
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    if isOwnService {
                        // Show edit option for own services
                        Button("Edit Service") {}
                            .buttonStyle(BRTRSecondaryButton())
                    } else {
                        Button("Propose a Trade") {
                            showProposeSheet = true
                        }
                        .buttonStyle(BRTRPrimaryButton())

                        Button("Send a Message") {
                            showMessageSheet = true
                        }
                        .buttonStyle(BRTRSecondaryButton())
                    }
                }
                .padding(20)
                .background(Color.brtrBackground)
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.brtrCard.opacity(0.9))
                    .clipShape(Circle())
            }
            .padding(.leading, 20)
            .padding(.top, 60)
        }
        .onAppear {
            isOwnService = authManager.currentUser?.id == service.userId
        }
        .sheet(isPresented: $showProposeSheet) {
            ProposeTradeSheet(service: service)
                .environmentObject(authManager)
                .environmentObject(barterManager)
        }
        .sheet(isPresented: $showMessageSheet) {
            // Navigate to messaging — placeholder until MessagesView is wired
            Text("Messaging coming soon")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.brtrBackground)
        }
    }

    // MARK: - Subviews
    private var heroPlaceholder: some View {
        ZStack {
            Color.brtrPurpleDim
            Image(systemName: service.serviceCategory.icon)
                .font(.system(size: 64))
                .foregroundColor(.brtrPurpleLight.opacity(0.3))
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.brtrPurple)
            .frame(width: 52, height: 52)
            .overlay(
                Text(String(service.owner.fullName.prefix(1)))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.brtrTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.brtrCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
    }
}

// MARK: - Propose Trade Sheet
struct ProposeTradeSheet: View {
    let service: Service
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var barterManager: BarterManager
    @EnvironmentObject var servicesManager: ServicesManager

    @State private var selectedServiceId: UUID?
    @State private var message = ""
    @State private var isSending = false
    @State private var didSend = false

    var myServices: [Service] { servicesManager.myServices }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()

                if didSend {
                    // Success state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.brtrGreen)
                        Text("Trade Proposed!")
                            .font(BRTRFont.title())
                            .foregroundColor(.white)
                        Text("We'll notify you when \(service.owner.username) responds.")
                            .font(BRTRFont.subheadline())
                            .foregroundColor(.brtrTextSecondary)
                            .multilineTextAlignment(.center)
                        Button("Done") { dismiss() }
                            .buttonStyle(BRTRPrimaryButton())
                            .padding(.top, 8)
                    }
                    .padding(32)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {

                            // They offer
                            VStack(alignment: .leading, spacing: 10) {
                                Text("They offer")
                                    .font(BRTRFont.caption())
                                    .foregroundColor(.brtrTextMuted)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                HStack(spacing: 12) {
                                    Image(systemName: service.serviceCategory.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(.brtrPurpleLight)
                                        .frame(width: 44, height: 44)
                                        .background(Color.brtrPurpleDim)
                                        .cornerRadius(10)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(service.title)
                                            .font(BRTRFont.headline())
                                            .foregroundColor(.white)
                                        Text(service.owner.username)
                                            .font(BRTRFont.caption())
                                            .foregroundColor(.brtrTextSecondary)
                                    }
                                }
                                .padding(14)
                                .brtrCard()
                            }

                            // You offer
                            VStack(alignment: .leading, spacing: 10) {
                                Text("You offer")
                                    .font(BRTRFont.caption())
                                    .foregroundColor(.brtrTextMuted)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                if myServices.isEmpty {
                                    Text("You have no active services. Create one first.")
                                        .font(BRTRFont.subheadline())
                                        .foregroundColor(.brtrTextSecondary)
                                        .padding(14)
                                        .brtrCard()
                                } else {
                                    ForEach(myServices) { myService in
                                        Button {
                                            selectedServiceId = myService.id
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: myService.serviceCategory.icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.brtrPurpleLight)
                                                    .frame(width: 44, height: 44)
                                                    .background(Color.brtrPurpleDim)
                                                    .cornerRadius(10)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(myService.title)
                                                        .font(BRTRFont.headline())
                                                        .foregroundColor(.white)
                                                    Text(myService.category)
                                                        .font(BRTRFont.caption())
                                                        .foregroundColor(.brtrTextSecondary)
                                                }

                                                Spacer()

                                                if selectedServiceId == myService.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.brtrPurple)
                                                }
                                            }
                                            .padding(14)
                                            .brtrCard()
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedServiceId == myService.id ? Color.brtrPurple : Color.clear, lineWidth: 1.5)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }

                            // Message
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Add a message (optional)")
                                    .font(BRTRFont.caption())
                                    .foregroundColor(.brtrTextMuted)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                TextField("Introduce yourself or describe the trade...", text: $message, axis: .vertical)
                                    .foregroundColor(.white)
                                    .lineLimit(4...6)
                                    .padding(14)
                                    .background(Color.brtrCard)
                                    .cornerRadius(12)
                            }

                            Button {
                                guard let selectedServiceId, let toUserId = service.user?.id else { return }
                                isSending = true
                                Task {
                                    await barterManager.sendRequest(
                                        toUserId: toUserId,
                                        offeredServiceId: selectedServiceId,
                                        requestedServiceId: service.id,
                                        message: message
                                    )
                                    isSending = false
                                    didSend = true
                                }
                            } label: {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Send Proposal")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .buttonStyle(BRTRPrimaryButton())
                            .disabled(selectedServiceId == nil || isSending)
                            .opacity(selectedServiceId == nil ? 0.5 : 1)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Propose a Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brtrTextSecondary)
                }
            }
            .task {
                await servicesManager.fetchMyServices()
            }
        }
    }
}
