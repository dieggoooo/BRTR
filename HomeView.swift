import SwiftUI

struct HomeView: View {
    @EnvironmentObject var servicesManager: ServicesManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedCategory: ServiceCategory = .all
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Good morning,")
                                    .font(BRTRFont.subheadline())
                                    .foregroundColor(.brtrTextSecondary)
                                Text(authManager.currentUser?.fullName ?? "User")
                                    .font(BRTRFont.title())
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Circle()
                                .fill(Color.brtrPurpleDim)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Group {
                                        if let avatarUrl = authManager.currentUser?.avatarUrl,
                                           let url = URL(string: avatarUrl) {
                                            AsyncImage(url: url) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Text(String(authManager.currentUser?.fullName.prefix(1) ?? "U"))
                                                    .foregroundColor(.white)
                                            }
                                        } else {
                                            Text(String(authManager.currentUser?.fullName.prefix(1) ?? "U"))
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 20)

                        // Search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.brtrTextMuted)
                            TextField("Search services...", text: $searchText)
                                .foregroundColor(.white)
                                .onSubmit {
                                    Task {
                                        await servicesManager.fetchServices(
                                            category: selectedCategory == .all ? nil : selectedCategory.rawValue,
                                            searchQuery: searchText.isEmpty ? nil : searchText
                                        )
                                    }
                                }
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    Task { await servicesManager.fetchServices() }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.brtrTextMuted)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.brtrCard)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)

                        // Category pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ServiceCategory.allCases, id: \.self) { category in
                                    Button {
                                        selectedCategory = category
                                        Task {
                                            await servicesManager.fetchServices(
                                                category: category == .all ? nil : category.rawValue,
                                                searchQuery: searchText.isEmpty ? nil : searchText
                                            )
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 13))
                                            Text(category.rawValue)
                                                .font(BRTRFont.subheadline())
                                        }
                                        .foregroundColor(selectedCategory == category ? .white : .brtrTextSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(selectedCategory == category ? Color.brtrPurple : Color.brtrCard)
                                        .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Services grid
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(selectedCategory == .all ? "All Services" : selectedCategory.rawValue)
                                    .font(BRTRFont.title2())
                                    .foregroundColor(.white)
                                Spacer()
                                if !servicesManager.services.isEmpty {
                                    Text("\(servicesManager.services.count) found")
                                        .font(BRTRFont.caption())
                                        .foregroundColor(.brtrTextMuted)
                                }
                            }
                            .padding(.horizontal, 20)

                            if servicesManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity)
                                    .padding(40)
                            } else if servicesManager.services.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 48))
                                        .foregroundColor(.brtrTextMuted)
                                    Text("No services found")
                                        .font(BRTRFont.headline())
                                        .foregroundColor(.brtrTextSecondary)
                                    Text("Try a different category or search term")
                                        .font(BRTRFont.caption())
                                        .foregroundColor(.brtrTextMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                            } else {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(minimum: 0), spacing: 12),
                                        GridItem(.flexible(minimum: 0), spacing: 12)
                                    ],
                                    spacing: 12
                                ) {
                                    ForEach(servicesManager.services) { service in
                                        NavigationLink(destination: ServiceDetailView(service: service)) {
                                            ServiceGridCard(service: service)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .task {
                await servicesManager.fetchServices()
            }
        }
    }
}

// MARK: - ServiceGridCard

struct ServiceGridCard: View {
    let service: Service

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image — fixed height
            ZStack(alignment: .topLeading) {
                if let imageUrl = service.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        categoryPlaceholder
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                } else {
                    categoryPlaceholder
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                }

                Text(service.serviceCategory.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.brtrPurple)
                    .cornerRadius(5)
                    .padding(8)
            }

            // Info — fixed height
            VStack(alignment: .leading, spacing: 5) {
                Text(service.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.brtrPurpleDim)
                        .frame(width: 15, height: 15)
                        .overlay(
                            Text(String(service.owner.fullName.prefix(1)))
                                .font(.system(size: 7))
                                .foregroundColor(.white)
                        )
                    Text(service.owner.username)
                        .font(.system(size: 10))
                        .foregroundColor(.brtrTextMuted)
                        .lineLimit(1)
                    Spacer()
                    if service.owner.rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", service.owner.rating))
                                .font(.system(size: 9))
                                .foregroundColor(.brtrTextMuted)
                        }
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 192)
        .background(Color.brtrCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brtrBorder, lineWidth: 1)
        )
        .clipped()
    }

    private var categoryPlaceholder: some View {
        LinearGradient(
            colors: [Color.brtrPurpleDim, Color.brtrCard],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: service.serviceCategory.icon)
                .font(.system(size: 28))
                .foregroundColor(.brtrPurpleLight.opacity(0.3))
        )
    }
}

// MARK: - ServiceCard (list style)
struct ServiceCard: View {
    let service: Service

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Color.brtrPurpleDim
                Image(systemName: service.serviceCategory.icon)
                    .font(.system(size: 22))
                    .foregroundColor(.brtrPurpleLight)
            }
            .frame(width: 72, height: 72)
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                Text(service.title)
                    .font(BRTRFont.headline())
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.brtrPurpleDim)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(String(service.owner.fullName.prefix(1)))
                                .font(.system(size: 9))
                                .foregroundColor(.white)
                        )
                    Text(service.owner.username)
                        .font(BRTRFont.caption())
                        .foregroundColor(.brtrTextSecondary)
                    if service.owner.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.brtrGreen)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", service.owner.rating))
                        .font(BRTRFont.caption())
                        .foregroundColor(.brtrTextSecondary)
                    Text("·")
                        .foregroundColor(.brtrTextMuted)
                    Text(service.displayEstimatedValue)
                        .font(BRTRFont.caption())
                        .foregroundColor(.brtrPurpleLight)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.brtrTextMuted)
        }
        .padding(16)
        .brtrCard()
        .padding(.horizontal, 20)
    }
}
