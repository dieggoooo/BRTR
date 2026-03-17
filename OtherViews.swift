import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            AddServiceView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(.brtrPurple)
    }
}

// MARK: - Search View
struct SearchView: View {
    @EnvironmentObject var servicesManager: ServicesManager
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @FocusState private var isSearchFocused: Bool
    @State private var recentSearches = ["Photography", "Design", "Tutoring", "iOS Development"]

    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case design = "Design"
        case development = "Development"
        case photography = "Photography"
        case tutoring = "Tutoring"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.brtrTextMuted)
                                    .font(.system(size: 16))

                                TextField("Search here...", text: $searchText)
                                    .foregroundColor(.white)
                                    .font(BRTRFont.body())
                                    .focused($isSearchFocused)
                                    .onSubmit {
                                        if !searchText.isEmpty {
                                            if !recentSearches.contains(searchText) {
                                                recentSearches.insert(searchText, at: 0)
                                            }
                                            Task {
                                                await servicesManager.fetchServices(searchQuery: searchText)
                                            }
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
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(SearchFilter.allCases, id: \.self) { filter in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedFilter = filter
                                        }
                                        Task {
                                            await servicesManager.fetchServices(
                                                category: filter == .all ? nil : filter.rawValue,
                                                searchQuery: searchText.isEmpty ? nil : searchText
                                            )
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            if filter == .all {
                                                Image(systemName: "line.3.horizontal")
                                                    .font(.system(size: 12))
                                            }
                                            Text(filter.rawValue)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(selectedFilter == filter ? .white : .brtrTextSecondary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedFilter == filter
                                                ? Color.brtrPurple
                                                : Color.brtrCard
                                        )
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedFilter == filter ? Color.clear : Color.brtrBorder, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    if searchText.isEmpty && servicesManager.services.isEmpty {
                        // Recent searches
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Searches")
                                    .font(BRTRFont.headline())
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Clear all") {
                                    recentSearches = []
                                }
                                .font(BRTRFont.subheadline())
                                .foregroundColor(.brtrPurpleLight)
                            }
                            .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(recentSearches, id: \.self) { search in
                                    Button {
                                        searchText = search
                                        Task { await servicesManager.fetchServices(searchQuery: search) }
                                    } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 18))
                                                .foregroundColor(.brtrTextMuted)
                                            Text(search)
                                                .font(BRTRFont.body())
                                                .foregroundColor(.white)
                                            Spacer()
                                            Button {
                                                recentSearches.removeAll { $0 == search }
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.brtrTextMuted)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                    }

                                    if search != recentSearches.last {
                                        Divider()
                                            .background(Color.brtrBorder)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    } else if !servicesManager.services.isEmpty {
                        // Results grid
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(servicesManager.services) { service in
                                    NavigationLink(destination: ServiceDetailView(service: service)) {
                                        ServiceGridCard(service: service)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Messages View
struct MessagesView: View {
    @EnvironmentObject var barterManager: BarterManager
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("Messages")
                            .font(BRTRFont.largeTitle())
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(20)

                    if barterManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
                            .frame(maxWidth: .infinity)
                            .padding(40)
                    } else {
                        let allBarters = (barterManager.incomingRequests + barterManager.outgoingRequests)
                            .filter { $0.status == .accepted }
                            .sorted { $0.createdAt > $1.createdAt }

                        if allBarters.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(.brtrTextMuted)
                                Text("No messages yet")
                                    .font(BRTRFont.headline())
                                    .foregroundColor(.brtrTextSecondary)
                                Text("Accepted barters will appear here")
                                    .font(BRTRFont.caption())
                                    .foregroundColor(.brtrTextMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        } else {
                            ScrollView {
                                ForEach(allBarters) { barter in
                                    NavigationLink(destination: ChatView(barter: barter)) {
                                        BarterConversationRow(barter: barter)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await barterManager.fetchRequests()
            }
        }
    }
}

// MARK: - Barter Conversation Row
struct BarterConversationRow: View {
    let barter: BarterRequest
    @EnvironmentObject var authManager: AuthManager

    var otherUser: UserProfile? {
        guard let currentId = authManager.currentUser?.id else { return nil }
        return barter.fromUserId == currentId ? barter.toUser : barter.fromUser
    }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.brtrPurple)
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(otherUser?.fullName.prefix(1) ?? "?"))
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(otherUser?.fullName ?? "Unknown")
                    .font(BRTRFont.headline())
                    .foregroundColor(.white)
                Text(barter.offeredService?.title ?? "Trade")
                    .font(BRTRFont.subheadline())
                    .foregroundColor(.brtrTextMuted)
                    .lineLimit(1)
            }

            Spacer()

            Text(barter.status.rawValue.capitalized)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.brtrPurpleLight)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.brtrPurpleDim)
                .cornerRadius(6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Chat View
struct ChatView: View {
    let barter: BarterRequest
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var messagingManager = MessagingManager.shared
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.brtrPurple)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(otherUserName.prefix(1)))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    Text(otherUserName)
                        .font(BRTRFont.headline())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.brtrCard)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messagingManager.messages) { message in
                                let isMe = message.senderId == authManager.currentUser?.id
                                HStack {
                                    if isMe { Spacer() }
                                    Text(message.content)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(isMe ? Color.brtrPurple : Color.brtrCard)
                                        .foregroundColor(.white)
                                        .cornerRadius(18)
                                        .id(message.id)
                                    if !isMe { Spacer() }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onAppear { scrollProxy = proxy }
                    .onChange(of: messagingManager.messages.count) {
                        if let last = messagingManager.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("Message...", text: $messageText)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.brtrCard)
                        .cornerRadius(24)

                    Button {
                        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let text = messageText
                        messageText = ""
                        Task {
                            await messagingManager.sendMessage(barterId: barter.id, content: text)
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.brtrPurple)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.brtrCard)
            }
        }
        .navigationBarHidden(true)
        .task {
            await messagingManager.fetchMessages(for: barter.id)
            await messagingManager.subscribeToMessages(for: barter.id)
            await messagingManager.markAsRead(barterId: barter.id)
        }
        .onDisappear {
            Task { await messagingManager.unsubscribe() }
        }
    }

    private var otherUserName: String {
        guard let currentId = authManager.currentUser?.id else { return "Chat" }
        return barter.fromUserId == currentId
            ? (barter.toUser?.fullName ?? "User")
            : (barter.fromUser?.fullName ?? "User")
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    var user: UserProfile? { authManager.currentUser }

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()

            if let user = user {
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        Group {
                            if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    avatarPlaceholder(user: user)
                                }
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                            } else {
                                avatarPlaceholder(user: user)
                            }
                        }

                        VStack(spacing: 6) {
                            HStack {
                                Text(user.fullName)
                                    .font(BRTRFont.title())
                                    .foregroundColor(.white)
                                if user.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.brtrGreen)
                                }
                            }
                            Text("@\(user.username)")
                                .font(BRTRFont.body())
                                .foregroundColor(.brtrTextSecondary)
                        }

                        if let bio = user.bio {
                            Text(bio)
                                .font(BRTRFont.body())
                                .foregroundColor(.brtrTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        // Stats
                        HStack(spacing: 0) {
                            statCell(value: "\(user.completedTrades)", label: "Trades")
                            Divider().background(Color.brtrBorder).frame(height: 40)
                            statCell(value: String(format: "%.1f", user.rating), label: "Rating")
                            Divider().background(Color.brtrBorder).frame(height: 40)
                            statCell(value: "\(user.reviewCount)", label: "Reviews")
                        }
                        .padding()
                        .brtrCard()
                        .padding(.horizontal, 20)

                        Button("Sign Out") {
                            Task { await authManager.signOut() }
                        }
                        .font(BRTRFont.body())
                        .foregroundColor(.red)
                        .padding()
                    }
                    .padding(.top, 40)
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
            }
        }
    }

    private func avatarPlaceholder(user: UserProfile) -> some View {
        Circle()
            .fill(Color.brtrPurple)
            .frame(width: 90, height: 90)
            .overlay(
                Text(String(user.fullName.prefix(1)))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(BRTRFont.title2())
                .foregroundColor(.white)
            Text(label)
                .font(BRTRFont.caption())
                .foregroundColor(.brtrTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Service View
struct AddServiceView: View {
    @EnvironmentObject var servicesManager: ServicesManager
    @Environment(\.dismiss) var dismiss

    @State private var serviceName = ""
    @State private var description = ""
    @State private var selectedCategory: ServiceCategory = .design
    @State private var exchangeOptions: Set<ExchangeOption> = [.barter]
    @State private var zipCode = ""
    @State private var barterRange: ClosedRange<Double> = 5...75
    @State private var currentImageIndex = 0

    enum ExchangeOption: String, CaseIterable, Hashable {
        case barter = "Barter"
        case cash = "Cash"
        case free = "Free"
    }

    let placeholderImages = ["photo", "photo.fill", "photo.circle", "photo.circle.fill", "photo.stack"]

    var isFormValid: Bool {
        !serviceName.isEmpty && !description.isEmpty
    }

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Image placeholder carousel
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.brtrCard)
                                    .frame(height: 200)
                                Image(systemName: placeholderImages[currentImageIndex])
                                    .font(.system(size: 48))
                                    .foregroundColor(.brtrTextMuted)
                            }
                            HStack(spacing: 6) {
                                ForEach(0..<5, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentImageIndex ? Color.white : Color.brtrTextMuted)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }

                        // Name
                        formField(label: "Product/Service Name*") {
                            TextField("Freelance Car Mechanic", text: $serviceName)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.brtrCard)
                                .cornerRadius(12)
                        }

                        // Description
                        formField(label: "Description*") {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $description)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(minHeight: 120)
                                    .padding(12)
                                    .scrollContentBackground(.hidden)
                                if description.isEmpty {
                                    Text("Describe your service...")
                                        .foregroundColor(.brtrTextSecondary.opacity(0.6))
                                        .font(.system(size: 16))
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            }
                            .background(Color.brtrCard)
                            .cornerRadius(12)
                        }

                        // Category
                        formField(label: "Category*") {
                            Menu {
                                ForEach(ServiceCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                                    Button(category.rawValue) { selectedCategory = category }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory.rawValue)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.brtrTextMuted)
                                }
                                .padding(16)
                                .background(Color.brtrCard)
                                .cornerRadius(12)
                            }
                        }

                        // Exchange options
                        formField(label: "Pick Your Exchange Options*") {
                            HStack(spacing: 12) {
                                ForEach(ExchangeOption.allCases, id: \.self) { option in
                                    Button {
                                        if exchangeOptions.contains(option) {
                                            exchangeOptions.remove(option)
                                        } else {
                                            exchangeOptions.insert(option)
                                        }
                                    } label: {
                                        Text(option.rawValue)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(exchangeOptions.contains(option) ? Color.brtrPurple : Color.clear)
                                            .cornerRadius(25)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(exchangeOptions.contains(option) ? Color.clear : Color.brtrBorder, lineWidth: 1.5)
                                            )
                                    }
                                }
                            }
                        }

                        // Zip code
                        formField(label: "Zip Code*") {
                            TextField("05555", text: $zipCode)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .padding(16)
                                .background(Color.brtrCard)
                                .cornerRadius(12)
                        }

                        // Barter range
                        formField(label: "Barter Range") {
                            VStack(spacing: 8) {
                                RangeSlider(range: $barterRange, bounds: 5...75)
                                HStack {
                                    Text("\(Int(barterRange.lowerBound)) mi")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.brtrPurple)
                                        .cornerRadius(20)
                                    Spacer()
                                    Text("\(Int(barterRange.upperBound)) mi")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.brtrPurple)
                                        .cornerRadius(20)
                                }
                            }
                        }

                        // Publish button
                        Button {
                            guard isFormValid else { return }
                            Task {
                                await servicesManager.createService(
                                    title: serviceName,
                                    description: description,
                                    category: selectedCategory.rawValue,
                                    imageData: nil
                                )
                                if servicesManager.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        } label: {
                            if servicesManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(12)
                            } else {
                                Text("Publish")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(isFormValid ? 1.0 : 0.5))
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(!isFormValid || servicesManager.isLoading)
                        .padding(.top, 8)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.brtrTextSecondary)
            content()
        }
    }
}

// MARK: - Range Slider
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>

    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0

    init(range: Binding<ClosedRange<Double>>, bounds: ClosedRange<Double>) {
        self._range = range
        self.bounds = bounds
        self._lowerValue = State(initialValue: range.wrappedValue.lowerBound)
        self._upperValue = State(initialValue: range.wrappedValue.upperBound)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.brtrTextMuted.opacity(0.3))
                    .frame(height: 4)

                Rectangle()
                    .fill(Color.brtrPurple)
                    .frame(width: activeRangeWidth(in: geometry.size.width), height: 4)
                    .offset(x: lowerThumbOffset(in: geometry.size.width))

                Circle()
                    .fill(Color.brtrPurple)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(x: lowerThumbOffset(in: geometry.size.width) - 12)
                    .gesture(
                        DragGesture().onChanged { value in
                            let percent = min(max(0, value.location.x / geometry.size.width), 1)
                            let newValue = bounds.lowerBound + percent * (bounds.upperBound - bounds.lowerBound)
                            lowerValue = min(newValue, upperValue - 5)
                            range = lowerValue...upperValue
                        }
                    )

                Circle()
                    .fill(Color.brtrPurple)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(x: upperThumbOffset(in: geometry.size.width) - 12)
                    .gesture(
                        DragGesture().onChanged { value in
                            let percent = min(max(0, value.location.x / geometry.size.width), 1)
                            let newValue = bounds.lowerBound + percent * (bounds.upperBound - bounds.lowerBound)
                            upperValue = max(newValue, lowerValue + 5)
                            range = lowerValue...upperValue
                        }
                    )
            }
        }
        .frame(height: 24)
    }

    private func lowerThumbOffset(in width: CGFloat) -> CGFloat {
        let percent = (lowerValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return percent * width
    }

    private func upperThumbOffset(in width: CGFloat) -> CGFloat {
        let percent = (upperValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return percent * width
    }

    private func activeRangeWidth(in width: CGFloat) -> CGFloat {
        let lowerPercent = (lowerValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        let upperPercent = (upperValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return (upperPercent - lowerPercent) * width
    }
}
