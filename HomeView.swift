import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var servicesManager: ServicesManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedCategory: ServiceCategory = .all
    @State private var searchText = ""
    @State private var selectedService: Service? = nil

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Header ────────────────────────────────────
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(greeting)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.brtrTextSecondary)
                                Text(authManager.currentUser?.fullName.components(separatedBy: " ").first ?? "there")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            NavigationLink(destination: ProfileView().environmentObject(authManager)) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.brtrPurple, .brtrPurpleDim],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)

                                    if let avatarUrl = authManager.currentUser?.avatarUrl,
                                       let url = URL(string: avatarUrl) {
                                        AsyncImage(url: url) { img in
                                            img.resizable().scaledToFill()
                                        } placeholder: {
                                            Text(String(authManager.currentUser?.fullName.prefix(1) ?? "U"))
                                                .font(.system(size: 17, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: 44, height: 44)
                                        .clipShape(Circle())
                                    } else {
                                        Text(String(authManager.currentUser?.fullName.prefix(1) ?? "U"))
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                        // ── Search bar ────────────────────────────────
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.brtrTextMuted)

                            TextField("Search listings...", text: $searchText)
                                .font(.system(size: 15))
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.brtrCard)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brtrBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // ── Category pills ────────────────────────────
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ServiceCategory.allCases, id: \.self) { cat in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { selectedCategory = cat }
                                        Task {
                                            await servicesManager.fetchServices(
                                                category: cat == .all ? nil : cat.rawValue,
                                                searchQuery: searchText.isEmpty ? nil : searchText
                                            )
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 11, weight: .semibold))
                                            Text(cat.rawValue)
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(selectedCategory == cat ? .white : .brtrTextSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color.brtrPurple : Color.brtrCard)
                                        .cornerRadius(20)
                                        .overlay(
                                            Capsule()
                                                .stroke(selectedCategory == cat ? Color.clear : Color.brtrBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 24)

                        // ── Section header ────────────────────────────
                        HStack {
                            Text(selectedCategory == .all ? "All Listings" : selectedCategory.rawValue)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            if !servicesManager.services.isEmpty {
                                Text("\(servicesManager.services.count) found")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.brtrTextMuted)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.brtrCard)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)

                        // // ── Grid ──────────────────────────────────────
                        if servicesManager.isLoading {
                            loadingGrid
                        } else if servicesManager.services.isEmpty {
                            emptyState
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
                                            .frame(height: 212)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 14)
                        }
                                                }
    // ── Loading skeleton ─────────────────────────────────────
    private var loadingGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 14
        ) {
            ForEach(0..<6, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding(.horizontal, 16)
    }

    // ── Empty state ──────────────────────────────────────────
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.brtrPurpleDim.opacity(0.3))
                    .frame(width: 90, height: 90)
                Image(systemName: selectedCategory == .all ? "square.grid.2x2" : selectedCategory.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.brtrPurpleLight.opacity(0.6))
            }
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No listings yet" : "No results found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Text(searchText.isEmpty
                     ? "Be the first to post a listing\nin \(selectedCategory == .all ? "any category" : selectedCategory.rawValue)"
                     : "Try adjusting your search\nor browse a different category")
                    .font(.system(size: 14))
                    .foregroundColor(.brtrTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.brtrCard)
                .frame(height: 140)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.brtrBorder).frame(height: 12).frame(maxWidth: .infinity)
                RoundedRectangle(cornerRadius: 4).fill(Color.brtrBorder).frame(height: 10).frame(width: 80)
            }
            .padding(12)
        }
        .background(Color.brtrCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brtrBorder, lineWidth: 1))
        .opacity(shimmer ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

// MARK: - ServiceGridCard

struct ServiceGridCard: View {
    let service: Service

    var body: some View {
        VStack(spacing: 0) {

            // Image — 130pt, never grows
            ZStack(alignment: .bottomLeading) {
                if let imageUrl = service.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .clipped()
            .overlay(
                LinearGradient(colors: [.clear, Color.black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
                    .allowsHitTesting(false)
            )
            .overlay(alignment: .bottomLeading) {
                if let val = service.estimatedValue, !val.isEmpty {
                    Text("$\(val)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.brtrPurple.opacity(0.92))
                        .cornerRadius(7)
                        .padding(8)
                }
            }

            // Info — 82pt, never grows
            VStack(alignment: .leading, spacing: 4) {
                Label(service.serviceCategory.rawValue.uppercased(), systemImage: service.serviceCategory.icon)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.4)
                    .foregroundColor(.brtrPurpleLight)
                    .lineLimit(1)

                Text(service.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, maxHeight: 36, alignment: .topLeading)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.brtrPurpleDim)
                        .frame(width: 15, height: 15)
                        .overlay(
                            Text(String(service.owner.fullName.prefix(1)))
                                .font(.system(size: 7, weight: .bold))
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
                                .foregroundColor(Color(hex: "#F5C518"))
                            Text(String(format: "%.1f", service.owner.rating))
                                .font(.system(size: 9))
                                .foregroundColor(.brtrTextMuted)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(height: 82)
            .clipped()
        }
        .frame(height: 212)
        .background(Color.brtrCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brtrBorder, lineWidth: 1))
        .clipped()
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Color.brtrPurpleDim.opacity(0.8), Color.brtrCard],
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

// MARK: - ProfileView (redesigned)

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var servicesManager: ServicesManager
    @State private var myListings: [Service] = []
    @State private var isLoadingListings = false
    @State private var showDeleteConfirm = false

    var user: UserProfile? { authManager.currentUser }

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()

            if let user = user {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Avatar + name ────────────────────────────
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.brtrPurple, .brtrPurpleDim],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 88, height: 88)
                                    .shadow(color: Color.brtrPurple.opacity(0.5), radius: 14)

                                if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Text(String(user.fullName.prefix(1)))
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 88, height: 88)
                                    .clipShape(Circle())
                                } else {
                                    Text(String(user.fullName.prefix(1)))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                if user.isVerified {
                                    Circle()
                                        .fill(Color.brtrBackground)
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.brtrGreen)
                                        )
                                        .offset(x: 32, y: 32)
                                }
                            }

                            VStack(spacing: 5) {
                                Text(user.fullName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Text("@\(user.username)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.brtrTextSecondary)
                                if let bio = user.bio {
                                    Text(bio)
                                        .font(.system(size: 13))
                                        .foregroundColor(.brtrTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                        .padding(.top, 2)
                                }
                            }
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 24)

                        // ── Stats row ────────────────────────────────
                        HStack(spacing: 0) {
                            statCell(value: "\(user.completedTrades)", label: "Trades", icon: "arrow.left.arrow.right")
                            divider
                            statCell(value: String(format: "%.1f", user.rating), label: "Rating", icon: "star.fill")
                            divider
                            statCell(value: "\(user.reviewCount)", label: "Reviews", icon: "bubble.left.fill")
                            divider
                            statCell(value: "\(myListings.count)", label: "Listings", icon: "square.grid.2x2.fill")
                        }
                        .padding(.vertical, 16)
                        .background(Color.brtrCard)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brtrBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                        // ── My Listings ──────────────────────────────
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("My Listings")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                if !myListings.isEmpty {
                                    Text("\(myListings.count)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.brtrPurpleLight)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.brtrPurpleDim.opacity(0.4))
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal, 20)

                            if isLoadingListings {
                                HStack {
                                    Spacer()
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
                                    Spacer()
                                }
                                .padding(20)
                            } else if myListings.isEmpty {
                                // Empty listings state
                                VStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.brtrPurpleDim.opacity(0.3))
                                            .frame(width: 64, height: 64)
                                        Image(systemName: "plus.square.dashed")
                                            .font(.system(size: 28))
                                            .foregroundColor(.brtrPurpleLight.opacity(0.7))
                                    }
                                    Text("No listings yet")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Tap + to post your first listing")
                                        .font(.system(size: 13))
                                        .foregroundColor(.brtrTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 36)
                            } else {
                                LazyVGrid(
                                    columns: [GridItem(.flexible(minimum: 0), spacing: 12), GridItem(.flexible(minimum: 0), spacing: 12)],
                                    spacing: 12
                                ) {
                                    ForEach(myListings) { service in
                                        NavigationLink(destination: ServiceDetailView(service: service)
                                            .environmentObject(authManager)
                                            .environmentObject(BarterManager.shared)
                                        ) {
                                            ServiceGridCard(service: service)
                                                .frame(height: 212)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 14)
                            }
                        }

                        // ── Account actions ──────────────────────────
                        VStack(spacing: 12) {
                            Button {
                                Task { await authManager.signOut() }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Delete Account")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                    }
                }
            } else {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await authManager.signOut() }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .task {
            guard let userId = authManager.currentUser?.id else { return }
            isLoadingListings = true
            do {
                let all = try await fetchUserListings(userId: userId)
                myListings = all
            } catch {}
            isLoadingListings = false
        }
    }

    private func fetchUserListings(userId: UUID) async throws -> [Service] {
        return servicesManager.services.filter { $0.userId == userId }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.brtrBorder)
            .frame(width: 1, height: 36)
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.brtrPurpleLight)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.brtrTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(1)
            AddServiceView()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(2)
            MessagesView()
                .tabItem { Label("Messages", systemImage: "message.fill") }
                .tag(3)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(.brtrPurple)
    }
}

// MARK: - ServiceCard (list style, kept for compatibility)

struct ServiceCard: View {
    let service: Service

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                if let imageUrl = service.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                        placeholder: { placeholderBg }
                } else {
                    placeholderBg
                }
            }
            .frame(width: 72, height: 72)
            .cornerRadius(12)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                Text(service.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 5) {
                    Circle().fill(Color.brtrPurpleDim).frame(width: 18, height: 18)
                        .overlay(Text(String(service.owner.fullName.prefix(1))).font(.system(size: 8)).foregroundColor(.white))
                    Text(service.owner.username)
                        .font(.system(size: 12)).foregroundColor(.brtrTextSecondary)
                    if service.owner.isVerified {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 11)).foregroundColor(.brtrGreen)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(Color(hex: "#F5C518"))
                    Text(String(format: "%.1f", service.owner.rating)).font(.system(size: 11)).foregroundColor(.brtrTextSecondary)
                    Text("·").foregroundColor(.brtrTextMuted)
                    Text(service.displayEstimatedValue).font(.system(size: 11)).foregroundColor(.brtrPurpleLight)
                }
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.brtrTextMuted).font(.system(size: 12))
        }
        .padding(14)
        .background(Color.brtrCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brtrBorder, lineWidth: 1))
    }

    private var placeholderBg: some View {
        LinearGradient(colors: [Color.brtrPurpleDim, Color.brtrCard], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(Image(systemName: service.serviceCategory.icon).font(.system(size: 22)).foregroundColor(.brtrPurpleLight.opacity(0.5)))
    }
}
