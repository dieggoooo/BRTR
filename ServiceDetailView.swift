import SwiftUI

struct ServiceDetailView: View {
    let service: Service
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var barterManager: BarterManager
    @EnvironmentObject var servicesManager: ServicesManager
    @State private var showProposeSheet = false
    @State private var showMessageSheet = false
    @State private var isOwnService = false

    private var isSaved: Bool {
        servicesManager.savedListingIds.contains(service.id)
    }

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

                        // Title block with trade intent
                        VStack(alignment: .leading, spacing: 10) {

                            // Type + category row
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: service.isProduct ? "shippingbox.fill" : "wrench.and.screwdriver.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(service.isProduct ? "PRODUCT" : "SERVICE")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(0.5)
                                }
                                .foregroundColor(service.isProduct ? Color(hex: "#F5A623") : .brtrPurpleLight)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(service.isProduct ? Color(hex: "#F5A623").opacity(0.15) : Color.brtrPurple.opacity(0.2))
                                .cornerRadius(6)

                                HStack(spacing: 4) {
                                    Image(systemName: service.serviceCategory.icon)
                                        .font(.system(size: 10))
                                    Text(service.serviceCategory.rawValue.uppercased())
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(0.5)
                                }
                                .foregroundColor(.brtrTextMuted)
                            }

                            Text(service.title)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)

                            // Trade intent card
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(service.isProduct ? Color(hex: "#F5A623").opacity(0.15) : Color.brtrPurple.opacity(0.2))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: service.isProduct ? "shippingbox.fill" : "wrench.and.screwdriver.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(service.isProduct ? Color(hex: "#F5A623") : .brtrPurpleLight)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("OFFERING")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.brtrTextMuted)
                                            .tracking(0.5)
                                        Text(service.isProduct ? "A product" : "A service")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    if let val = service.estimatedValue, !val.isEmpty {
                                        Text("~$\(val)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.brtrPurpleLight)
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(Color.brtrPurpleDim.opacity(0.5))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(14)

                                Divider().background(Color.brtrBorder).padding(.horizontal, 14)

                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.brtrCard)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.brtrTextSecondary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("IN EXCHANGE FOR")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.brtrTextMuted)
                                            .tracking(0.5)
                                        if let seeking = service.seekingInReturn, !seeking.isEmpty {
                                            Text(seeking)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("Open to offers")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.brtrTextSecondary)
                                        }
                                    }
                                    Spacer()
                                    Text(service.flexibilityLabel)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.brtrTextSecondary)
                                        .padding(.horizontal, 7).padding(.vertical, 3)
                                        .background(Color.brtrCard)
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brtrBorder, lineWidth: 1))
                                }
                                .padding(14)
                            }
                            .background(Color.brtrCard)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brtrBorder, lineWidth: 1))
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
                        }
                        .padding(16)
                        .brtrCard()

                        // Description
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About this listing")
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
                        Button("Edit Listing") {}
                            .buttonStyle(BRTRSecondaryButton())
                    } else {
                        Button {
                            showProposeSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                Text("Offer a Trade")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.brtrPurple)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())

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
        // Bookmark button — top right
        .overlay(alignment: .topTrailing) {
            Button {
                Task { await servicesManager.toggleSave(service.id) }
            } label: {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSaved ? .brtrPurple : .white)
                    .frame(width: 40, height: 40)
                    .background(Color.brtrCard.opacity(0.9))
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.top, 60)
        }
        .onAppear {
            isOwnService = authManager.currentUser?.id == service.userId
        }
        .sheet(isPresented: $showProposeSheet) {
            ProposeTradeSheet(service: service)
                .environmentObject(authManager)
                .environmentObject(barterManager)
                .environmentObject(servicesManager)
        }
        .sheet(isPresented: $showMessageSheet) {
            Text("Messaging coming soon")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.brtrBackground)
        }
    }

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

                            VStack(alignment: .leading, spacing: 10) {
                                Text("You offer")
                                    .font(BRTRFont.caption())
                                    .foregroundColor(.brtrTextMuted)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                if myServices.isEmpty {
                                    Text("You have no active listings. Create one first.")
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
