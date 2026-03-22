import SwiftUI

// MARK: - Trade Type Filter
enum TradeTypeFilter: String, CaseIterable {
    case all = "all"
    case serviceForProduct = "s_for_p"
    case productForService = "p_for_s"
    case serviceForService = "s_for_s"
    case productForProduct = "p_for_p"

    var label: String {
        switch self {
        case .all: return "All Types"
        case .serviceForProduct: return "Service for Product"
        case .productForService: return "Product for Service"
        case .serviceForService: return "Service for Service"
        case .productForProduct: return "Product for Product"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .serviceForProduct: return "wrench.and.screwdriver"
        case .productForService: return "shippingbox"
        case .serviceForService: return "arrow.left.arrow.right"
        case .productForProduct: return "shippingbox.fill"
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var servicesManager: ServicesManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedCategory: ServiceCategory = .all
    @State private var selectedTradeType: TradeTypeFilter = .all
    @State private var searchText = ""

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }

    private var filteredServices: [Service] {
        servicesManager.services.filter { service in
            switch selectedTradeType {
            case .all: return true
            case .serviceForProduct: return !service.isProduct
            case .productForService: return service.isProduct
            case .serviceForService: return !service.isProduct
            case .productForProduct: return service.isProduct
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Header
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
                            NavigationLink(destination: ProfileView().environmentObject(authManager).environmentObject(servicesManager)) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.brtrPurple, .brtrPurpleDim], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 44, height: 44)
                                    if let avatarUrl = authManager.currentUser?.avatarUrl, let url = URL(string: avatarUrl) {
                                        AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: {
                                            Text(String(authManager.currentUser?.fullName.prefix(1) ?? "U"))
                                                .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                                        }
                                        .frame(width: 44, height: 44).clipShape(Circle())
                                    } else {
                                        Text(String(authManager.currentUser?.fullName.prefix(1) ?? "U"))
                                            .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 20)

                        // Search bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .medium)).foregroundColor(.brtrTextMuted)
                            TextField("Search listings...", text: $searchText)
                                .font(.system(size: 15)).foregroundColor(.white)
                                .onSubmit {
                                    Task { await servicesManager.fetchServices(category: selectedCategory == .all ? nil : selectedCategory.rawValue, searchQuery: searchText.isEmpty ? nil : searchText) }
                                }
                            if !searchText.isEmpty {
                                Button { searchText = ""; Task { await servicesManager.fetchServices() } } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.brtrTextMuted)
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(Color.brtrCard).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brtrBorder, lineWidth: 1))
                        .padding(.horizontal, 20).padding(.bottom, 20)

                        // Category pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ServiceCategory.allCases, id: \.self) { cat in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { selectedCategory = cat }
                                        Task { await servicesManager.fetchServices(category: cat == .all ? nil : cat.rawValue, searchQuery: searchText.isEmpty ? nil : searchText) }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: cat.icon).font(.system(size: 11, weight: .semibold))
                                            Text(cat.rawValue).font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(selectedCategory == cat ? .white : .brtrTextSecondary)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color.brtrPurple : Color.brtrCard)
                                        .cornerRadius(20)
                                        .overlay(Capsule().stroke(selectedCategory == cat ? Color.clear : Color.brtrBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 10)

                        // Trade type filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TradeTypeFilter.allCases, id: \.self) { filter in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { selectedTradeType = filter }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: filter.icon).font(.system(size: 10, weight: .semibold))
                                            Text(filter.label).font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(selectedTradeType == filter ? .white : .brtrTextSecondary)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(selectedTradeType == filter ? Color.brtrPurpleDim : Color.brtrCard)
                                        .cornerRadius(20)
                                        .overlay(Capsule().stroke(selectedTradeType == filter ? Color.brtrPurple : Color.brtrBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)

                        // Section header
                        HStack {
                            Text(selectedCategory == .all ? "All Listings" : selectedCategory.rawValue)
                                .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            if !servicesManager.services.isEmpty {
                                Text("\(filteredServices.count) found")
                                    .font(.system(size: 12, weight: .medium)).foregroundColor(.brtrTextMuted)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.brtrCard).cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 20).padding(.bottom, 14)

                        // Barter explainer banner
                        if !servicesManager.services.isEmpty && !servicesManager.isLoading {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.brtrPurple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Trade skills and goods")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Offer your service or product in exchange for theirs")
                                        .font(.system(size: 11))
                                        .foregroundColor(.brtrTextSecondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(Color.brtrPurple.opacity(0.12))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrPurple.opacity(0.25), lineWidth: 1))
                            .padding(.horizontal, 14).padding(.bottom, 14)
                        }

                        // Grid
                        if servicesManager.isLoading {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(0..<6, id: \.self) { _ in SkeletonCard() }
                            }
                            .padding(.horizontal, 14)
                        } else if filteredServices.isEmpty {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle().fill(Color.brtrPurpleDim.opacity(0.3)).frame(width: 90, height: 90)
                                    Image(systemName: selectedCategory == .all ? "square.grid.2x2" : selectedCategory.icon)
                                        .font(.system(size: 36)).foregroundColor(.brtrPurpleLight.opacity(0.6))
                                }
                                VStack(spacing: 8) {
                                    Text(searchText.isEmpty ? "No listings yet" : "No results found")
                                        .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                                    Text(searchText.isEmpty ? "Be the first to post a listing" : "Try a different search or category")
                                        .font(.system(size: 14)).foregroundColor(.brtrTextSecondary).multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 60).padding(.horizontal, 40)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(minimum: 0), spacing: 12), GridItem(.flexible(minimum: 0), spacing: 12)], spacing: 12) {
                                ForEach(filteredServices) { service in
                                    NavigationLink(destination: ServiceDetailView(service: service)) {
                                        ServiceGridCard(service: service)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(height: 212)
                                }
                            }
                            .padding(.horizontal, 14)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await servicesManager.fetchServices()
                await servicesManager.fetchSavedListings()
            }
        }
    }
}

// MARK: - SkeletonCard

struct SkeletonCard: View {
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 0).fill(Color.brtrCard).frame(height: 120)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.brtrBorder).frame(height: 12).frame(maxWidth: .infinity)
                RoundedRectangle(cornerRadius: 4).fill(Color.brtrBorder).frame(height: 10).frame(width: 80)
            }
            .padding(12)
        }
        .frame(height: 212)
        .background(Color.brtrCard).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brtrBorder, lineWidth: 1))
        .opacity(shimmer ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { shimmer = true }
        }
    }
}

// MARK: - ServiceGridCard
struct ServiceGridCard: View {
    let service: Service
    @EnvironmentObject var servicesManager: ServicesManager

    private var isSaved: Bool {
        servicesManager.savedListingIds.contains(service.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image section
            ZStack(alignment: .bottom) {
                Group {
                    if let imageUrl = service.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                categoryPlaceholder
                            }
                        }
                    } else {
                        categoryPlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipped()

                // Gradient fade
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 48)

                // Wants chip
                if let seeking = service.seekingInReturn, !seeking.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 8, weight: .bold))
                        Text("Wants: \(seeking)")
                            .font(.system(size: 9, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .clipped()
            // Bookmark button — top right of image
            .overlay(alignment: .topTrailing) {
                Button {
                    Task { await servicesManager.toggleSave(service.id) }
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSaved ? .brtrPurple : .white)
                        .padding(7)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .padding(8)
                .buttonStyle(PlainButtonStyle())
            }

            // Info section
            VStack(alignment: .leading, spacing: 0) {

                // Type pill + category row
                HStack(spacing: 5) {
                    HStack(spacing: 3) {
                        Image(systemName: service.isProduct ? "shippingbox.fill" : "wrench.and.screwdriver.fill")
                            .font(.system(size: 7, weight: .bold))
                        Text(service.isProduct ? "PRODUCT" : "SERVICE")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.4)
                    }
                    .foregroundColor(service.isProduct ? Color(hex: "#F5A623") : .brtrPurpleLight)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        service.isProduct
                            ? Color(hex: "#F5A623").opacity(0.15)
                            : Color.brtrPurple.opacity(0.2)
                    )
                    .cornerRadius(5)

                    HStack(spacing: 3) {
                        Image(systemName: service.serviceCategory.icon)
                            .font(.system(size: 8, weight: .semibold))
                        Text(service.serviceCategory.rawValue.uppercased())
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(0.3)
                    }
                    .foregroundColor(.brtrTextMuted)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // Title
                Text(service.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)

                Spacer(minLength: 0)

                // Owner row
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
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 212)
        .background(Color.brtrCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
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
        HStack(spacing: 14) {
            ZStack {
                if let imageUrl = service.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { placeholderBg }
                } else { placeholderBg }
            }
            .frame(width: 72, height: 72).cornerRadius(12).clipped()

            VStack(alignment: .leading, spacing: 5) {
                Text(service.title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white).lineLimit(2)
                HStack(spacing: 5) {
                    Circle().fill(Color.brtrPurpleDim).frame(width: 18, height: 18)
                        .overlay(Text(String(service.owner.fullName.prefix(1))).font(.system(size: 8)).foregroundColor(.white))
                    Text(service.owner.username).font(.system(size: 12)).foregroundColor(.brtrTextSecondary)
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
        .padding(14).background(Color.brtrCard).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brtrBorder, lineWidth: 1))
    }

    private var placeholderBg: some View {
        LinearGradient(colors: [Color.brtrPurpleDim, Color.brtrCard], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(Image(systemName: service.serviceCategory.icon).font(.system(size: 22)).foregroundColor(.brtrPurpleLight.opacity(0.5)))
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

// MARK: - ProfileView

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var servicesManager: ServicesManager
    @State private var myListings: [Service] = []
    @State private var isLoadingListings = false
    @State private var showDeleteConfirm = false
    @State private var selectedProfileTab: ProfileTab = .listings

    enum ProfileTab { case listings, saved }

    var user: UserProfile? { authManager.currentUser }

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()

            if let user = user {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // Avatar + name
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.brtrPurple, .brtrPurpleDim], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 88, height: 88)
                                    .shadow(color: Color.brtrPurple.opacity(0.5), radius: 14)
                                if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: {
                                        Text(String(user.fullName.prefix(1))).font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                                    }
                                    .frame(width: 88, height: 88).clipShape(Circle())
                                } else {
                                    Text(String(user.fullName.prefix(1))).font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                                }
                                if user.isVerified {
                                    Circle().fill(Color.brtrBackground).frame(width: 26, height: 26)
                                        .overlay(Image(systemName: "checkmark.seal.fill").font(.system(size: 20)).foregroundColor(.brtrGreen))
                                        .offset(x: 32, y: 32)
                                }
                            }
                            VStack(spacing: 5) {
                                Text(user.fullName).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                Text("@\(user.username)").font(.system(size: 14)).foregroundColor(.brtrTextSecondary)
                                if let bio = user.bio {
                                    Text(bio).font(.system(size: 13)).foregroundColor(.brtrTextSecondary)
                                        .multilineTextAlignment(.center).padding(.horizontal, 40).padding(.top, 2)
                                }
                            }
                        }
                        .padding(.top, 32).padding(.bottom, 24)

                        // Stats row
                        HStack(spacing: 0) {
                            statCell(value: "\(user.completedTrades)", label: "Trades", icon: "arrow.left.arrow.right")
                            Rectangle().fill(Color.brtrBorder).frame(width: 1, height: 36)
                            statCell(value: String(format: "%.1f", user.rating), label: "Rating", icon: "star.fill")
                            Rectangle().fill(Color.brtrBorder).frame(width: 1, height: 36)
                            statCell(value: "\(user.reviewCount)", label: "Reviews", icon: "bubble.left.fill")
                            Rectangle().fill(Color.brtrBorder).frame(width: 1, height: 36)
                            statCell(value: "\(myListings.count)", label: "Listings", icon: "square.grid.2x2.fill")
                        }
                        .padding(.vertical, 16)
                        .background(Color.brtrCard).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brtrBorder, lineWidth: 1))
                        .padding(.horizontal, 20).padding(.bottom, 28)

                        // Tab switcher: My Listings / Saved
                        HStack(spacing: 0) {
                            profileTabButton(label: "My Listings", icon: "square.grid.2x2.fill", tab: .listings)
                            profileTabButton(label: "Saved", icon: "bookmark.fill", tab: .saved)
                        }
                        .background(Color.brtrCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
                        .padding(.horizontal, 20).padding(.bottom, 20)

                        // Tab content
                        if selectedProfileTab == .listings {
                            listingsGrid
                        } else {
                            savedGrid
                        }

                        // Account actions
                        VStack(spacing: 12) {
                            Button { Task { await authManager.signOut() } } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .font(.system(size: 15, weight: .semibold)).foregroundColor(.red.opacity(0.8))
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Color.red.opacity(0.08)).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button { showDeleteConfirm = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Delete Account")
                                }
                                .font(.system(size: 14, weight: .medium)).foregroundColor(.red.opacity(0.5))
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20).padding(.top, 32).padding(.bottom, 48)
                    }
                }
            } else {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { Task { await authManager.signOut() } }
        } message: {
            Text("Are you sure? This action cannot be undone.")
        }
        .task {
            guard let userId = authManager.currentUser?.id else { return }
            isLoadingListings = true
            myListings = servicesManager.services.filter { $0.userId == userId }
            isLoadingListings = false
            await servicesManager.fetchSavedListings()
        }
    }

    // MARK: - My Listings grid
    private var listingsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Listings").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Spacer()
                if !myListings.isEmpty {
                    Text("\(myListings.count)").font(.system(size: 12, weight: .semibold)).foregroundColor(.brtrPurpleLight)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.brtrPurpleDim.opacity(0.4)).cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)

            if isLoadingListings {
                HStack { Spacer(); ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple)); Spacer() }.padding(20)
            } else if myListings.isEmpty {
                emptyState(icon: "plus.square.dashed", title: "No listings yet", subtitle: "Tap + to post your first listing")
            } else {
                LazyVGrid(columns: [GridItem(.flexible(minimum: 0), spacing: 12), GridItem(.flexible(minimum: 0), spacing: 12)], spacing: 12) {
                    ForEach(myListings) { service in
                        NavigationLink(destination: ServiceDetailView(service: service).environmentObject(authManager).environmentObject(BarterManager.shared)) {
                            ServiceGridCard(service: service)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(height: 212)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    // MARK: - Saved grid
    private var savedGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Saved Listings").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Spacer()
                if !servicesManager.savedListings.isEmpty {
                    Text("\(servicesManager.savedListings.count)").font(.system(size: 12, weight: .semibold)).foregroundColor(.brtrPurpleLight)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.brtrPurpleDim.opacity(0.4)).cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)

            if servicesManager.savedListings.isEmpty {
                emptyState(icon: "bookmark", title: "Nothing saved yet", subtitle: "Tap the bookmark on any listing to save it")
            } else {
                LazyVGrid(columns: [GridItem(.flexible(minimum: 0), spacing: 12), GridItem(.flexible(minimum: 0), spacing: 12)], spacing: 12) {
                    ForEach(servicesManager.savedListings) { service in
                        NavigationLink(destination: ServiceDetailView(service: service).environmentObject(authManager).environmentObject(BarterManager.shared)) {
                            ServiceGridCard(service: service)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(height: 212)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private func profileTabButton(label: String, icon: String, tab: ProfileTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) { selectedProfileTab = tab }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(selectedProfileTab == tab ? .white : .brtrTextMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(selectedProfileTab == tab ? Color.brtrPurple : Color.clear)
            .cornerRadius(10)
            .padding(3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.brtrPurpleDim.opacity(0.3)).frame(width: 64, height: 64)
                Image(systemName: icon).font(.system(size: 28)).foregroundColor(.brtrPurpleLight.opacity(0.7))
            }
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
            Text(subtitle).font(.system(size: 13)).foregroundColor(.brtrTextSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 36).padding(.horizontal, 20)
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(.brtrPurpleLight)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.brtrTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
