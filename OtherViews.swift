import SwiftUI
import PhotosUI

// MARK: - Supporting Enums

enum ListingType {
    case product, service
}

enum ProductCondition: String, CaseIterable {
    case new = "New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case heavilyUsed = "Heavily Used"
}

enum DeliveryMethod: String, CaseIterable, Hashable {
    case pickupOnly = "Pick up only"
    case meetHalfway = "Meet halfway"
    case willShip = "Will ship"
}

enum ServiceScope: String, CaseIterable {
    case oneTime = "One-time task"
    case halfDay = "Half day"
    case multiDay = "Multi-day"
    case recurring = "Recurring"
}

enum ServiceMode: String, CaseIterable {
    case remote = "Remote"
    case inPerson = "In-person"
    case either = "Either"
}

enum ExperienceLevel: String, CaseIterable {
    case student = "Student"
    case hobbyist = "Hobbyist"
    case professional = "Professional"
    case expert = "Expert"
}

// MARK: - Main Tab View

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
                                Image(systemName: "magnifyingglass").foregroundColor(.brtrTextMuted).font(.system(size: 16))
                                TextField("Search here...", text: $searchText)
                                    .foregroundColor(.white).font(BRTRFont.body()).focused($isSearchFocused)
                                    .onSubmit {
                                        if !searchText.isEmpty {
                                            if !recentSearches.contains(searchText) { recentSearches.insert(searchText, at: 0) }
                                            Task { await servicesManager.fetchServices(searchQuery: searchText) }
                                        }
                                    }
                                if !searchText.isEmpty {
                                    Button { searchText = ""; Task { await servicesManager.fetchServices() } } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.brtrTextMuted)
                                    }
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(Color.white.opacity(0.95)).cornerRadius(12)
                        }
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(SearchFilter.allCases, id: \.self) { filter in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { selectedFilter = filter }
                                        Task { await servicesManager.fetchServices(category: filter == .all ? nil : filter.rawValue, searchQuery: searchText.isEmpty ? nil : searchText) }
                                    } label: {
                                        HStack(spacing: 6) {
                                            if filter == .all { Image(systemName: "line.3.horizontal").font(.system(size: 12)) }
                                            Text(filter.rawValue).font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(selectedFilter == filter ? .white : .brtrTextSecondary)
                                        .padding(.horizontal, 18).padding(.vertical, 12)
                                        .background(selectedFilter == filter ? Color.brtrPurple : Color.brtrCard)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(selectedFilter == filter ? Color.clear : Color.brtrBorder, lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 16).padding(.bottom, 20)

                    if searchText.isEmpty && servicesManager.services.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Searches").font(BRTRFont.headline()).foregroundColor(.white)
                                Spacer()
                                Button("Clear all") { recentSearches = [] }.font(BRTRFont.subheadline()).foregroundColor(.brtrPurpleLight)
                            }
                            .padding(.horizontal, 20)
                            VStack(spacing: 0) {
                                ForEach(recentSearches, id: \.self) { search in
                                    Button { searchText = search; Task { await servicesManager.fetchServices(searchQuery: search) } } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: "clock").font(.system(size: 18)).foregroundColor(.brtrTextMuted)
                                            Text(search).font(BRTRFont.body()).foregroundColor(.white)
                                            Spacer()
                                            Button { recentSearches.removeAll { $0 == search } } label: {
                                                Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(.brtrTextMuted)
                                            }
                                        }
                                        .padding(.horizontal, 20).padding(.vertical, 16)
                                    }
                                    if search != recentSearches.last { Divider().background(Color.brtrBorder).padding(.horizontal, 20) }
                                }
                            }
                        }
                        .padding(.top, 8)
                    } else if !servicesManager.services.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(minimum: 0), spacing: 12), GridItem(.flexible(minimum: 0), spacing: 12)], spacing: 12) {
                                ForEach(servicesManager.services) { service in
                                    NavigationLink(destination: ServiceDetailView(service: service)) { ServiceGridCard(service: service) }
                                        .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
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
                        Group {
                            if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { avatarPlaceholder(user: user) }
                                    .frame(width: 90, height: 90).clipShape(Circle())
                            } else { avatarPlaceholder(user: user) }
                        }
                        VStack(spacing: 6) {
                            HStack {
                                Text(user.fullName).font(BRTRFont.title()).foregroundColor(.white)
                                if user.isVerified { Image(systemName: "checkmark.seal.fill").foregroundColor(.brtrGreen) }
                            }
                            Text("@\(user.username)").font(BRTRFont.body()).foregroundColor(.brtrTextSecondary)
                        }
                        if let bio = user.bio {
                            Text(bio).font(BRTRFont.body()).foregroundColor(.brtrTextSecondary).multilineTextAlignment(.center).padding(.horizontal, 32)
                        }
                        HStack(spacing: 0) {
                            statCell(value: "\(user.completedTrades)", label: "Trades")
                            Divider().background(Color.brtrBorder).frame(height: 40)
                            statCell(value: String(format: "%.1f", user.rating), label: "Rating")
                            Divider().background(Color.brtrBorder).frame(height: 40)
                            statCell(value: "\(user.reviewCount)", label: "Reviews")
                        }
                        .padding().brtrCard().padding(.horizontal, 20)
                        Button("Sign Out") { Task { await authManager.signOut() } }.font(BRTRFont.body()).foregroundColor(.red).padding()
                    }
                    .padding(.top, 40)
                }
            } else {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .brtrPurple))
            }
        }
    }

    private func avatarPlaceholder(user: UserProfile) -> some View {
        Circle().fill(Color.brtrPurple).frame(width: 90, height: 90)
            .overlay(Text(String(user.fullName.prefix(1))).font(.system(size: 36, weight: .bold)).foregroundColor(.white))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(BRTRFont.title2()).foregroundColor(.white)
            Text(label).font(BRTRFont.caption()).foregroundColor(.brtrTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Service View

struct AddServiceView: View {
    @EnvironmentObject var servicesManager: ServicesManager
    @Environment(\.dismiss) var dismiss

    @State private var listingType: ListingType = .service
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var currentImageIndex = 0

    // Shared
    @State private var serviceName = ""
    @State private var description = ""
    @State private var selectedCategory: ServiceCategory = .design
    @State private var estimatedValue = ""
    @State private var seekingInReturn = ""
    @State private var tradeFlexibility: Double = 65
    @State private var zipCode = ""
    @State private var barterRange: ClosedRange<Double> = 5...75
    @State private var exchangeOptions: Set<ExchangeOption> = [.barter]

    // Product
    @State private var condition: ProductCondition? = nil
    @State private var brand = ""
    @State private var modelYear = ""
    @State private var weightLbs = ""
    @State private var dimensions = ""
    @State private var deliveryMethods: Set<DeliveryMethod> = []
    @State private var hasOriginalBox = false
    @State private var hasReceipt = false
    @State private var hasSerialNumber = false

    // Service
    @State private var scope: ServiceScope? = nil
    @State private var serviceMode: ServiceMode? = nil
    @State private var experienceLevel: ExperienceLevel? = nil
    @State private var availableDays: Set<String> = []
    @State private var portfolioLink = ""
    @State private var materialsNote = ""

    enum ExchangeOption: String, CaseIterable, Hashable {
        case barter = "Barter"; case cash = "Cash"; case free = "Free"
    }

    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    var isFormValid: Bool { !serviceName.isEmpty && !description.isEmpty }
    var flexibilityLabel: String {
        switch Int(tradeFlexibility) {
        case 0..<20: return "Firm on terms"; case 20..<40: return "Mostly firm"
        case 40..<60: return "Open to offers"; case 60..<80: return "Very flexible"
        default: return "Any offer welcome"
        }
    }

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).foregroundColor(.white).frame(width: 44, height: 44) }
                    Spacer()
                    Text("Add Listing").font(BRTRFont.headline()).foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).frame(width: 44, height: 44) }
                }
                .padding(.horizontal, 20).padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        imageCarouselSection
                        typeFilterButtons.padding(.horizontal, 20)
                        sharedBasicsSection.padding(.horizontal, 20)
                        if listingType == .product { productFieldsSection.padding(.horizontal, 20) }
                        else { serviceFieldsSection.padding(.horizontal, 20) }
                        barterCoreSection.padding(.horizontal, 20)
                        publishButton.padding(.horizontal, 20)
                        Spacer(minLength: 60)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var imageCarouselSection: some View {
        VStack(spacing: 10) {
            ZStack {
                if selectedImages.isEmpty {
                    ZStack {
                        Color.brtrCard
                        VStack(spacing: 10) {
                            Image(systemName: "photo.badge.plus").font(.system(size: 40)).foregroundColor(.brtrTextMuted)
                            Text("Tap to add photos").font(BRTRFont.subheadline()).foregroundColor(.brtrTextMuted)
                        }
                    }
                    .frame(height: 220)
                } else {
                    TabView(selection: $currentImageIndex) {
                        ForEach(selectedImages.indices, id: \.self) { idx in
                            Image(uiImage: selectedImages[idx]).resizable().scaledToFill().frame(height: 220).clipped().tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 220)
                    Button { selectedImages.remove(at: currentImageIndex); if currentImageIndex > 0 { currentImageIndex -= 1 } } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundColor(.white).shadow(radius: 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(12)
                }
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    HStack(spacing: 6) { Image(systemName: "plus").font(.system(size: 12, weight: .bold)); Text("Add photos").font(.system(size: 12, weight: .semibold)) }
                        .foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 7).background(Color.brtrPurple.opacity(0.9)).cornerRadius(20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(12)
            }
            .frame(height: 220)
            .onChange(of: selectedPhotos) { newItems in
                Task {
                    var images: [UIImage] = []
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) { images.append(img) }
                    }
                    selectedImages = images; currentImageIndex = 0
                }
            }
            if !selectedImages.isEmpty {
                HStack(spacing: 6) {
                    ForEach(selectedImages.indices, id: \.self) { idx in
                        Circle().fill(idx == currentImageIndex ? Color.white : Color.brtrTextMuted.opacity(0.5)).frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    private var typeFilterButtons: some View {
        HStack(spacing: 8) {
            typeFilterButton(label: "Service", icon: "wrench.and.screwdriver", type: .service)
            typeFilterButton(label: "Product", icon: "shippingbox", type: .product)
            Spacer()
        }
    }

    private func typeFilterButton(label: String, icon: String, type: ListingType) -> some View {
        let isSelected = listingType == type
        return Button { withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { listingType = type } } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "\(icon).fill" : icon).font(.system(size: 12))
                Text(label).font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .brtrTextSecondary)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(isSelected ? Color.brtrPurple : Color.brtrCard).cornerRadius(20)
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.brtrBorder, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var sharedBasicsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            formField(label: listingType == .product ? "Item Name*" : "Service Name*") {
                TextField(listingType == .product ? "e.g. Sony WH-1000XM5 Headphones" : "e.g. Brand Identity Design", text: $serviceName).brtrInputStyle()
            }
            formField(label: "Description*") {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $description).font(.system(size: 15)).foregroundColor(.white).frame(minHeight: 90).padding(12).scrollContentBackground(.hidden)
                    if description.isEmpty {
                        Text(listingType == .product ? "Describe condition, history, what's included..." : "Describe what you offer, your process, deliverables...")
                            .foregroundColor(.brtrTextSecondary.opacity(0.6)).font(.system(size: 15)).padding(16).allowsHitTesting(false)
                    }
                }
                .background(Color.brtrCard).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
            }
            formField(label: "Category*") {
                Menu {
                    ForEach(ServiceCategory.allCases.filter { $0 != .all }, id: \.self) { cat in Button(cat.rawValue) { selectedCategory = cat } }
                } label: {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: selectedCategory.icon).font(.system(size: 14)).foregroundColor(.brtrPurpleLight)
                            Text(selectedCategory.rawValue).font(.system(size: 15)).foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundColor(.brtrTextMuted)
                    }
                    .padding(14).background(Color.brtrCard).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
                }
            }
        }
    }

    private var productFieldsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionDivider(label: "Product Info", icon: "shippingbox.fill")
            formField(label: "Condition*") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(ProductCondition.allCases, id: \.self) { c in pillToggle(label: c.rawValue, isSelected: condition == c) { condition = (condition == c) ? nil : c } }
                }
            }
            HStack(alignment: .top, spacing: 12) {
                formField(label: "Brand / Model") { TextField("e.g. Sony WH-1000XM5", text: $brand).brtrInputStyle() }
                formField(label: "Year") { TextField("2023", text: $modelYear).keyboardType(.numberPad).brtrInputStyle().frame(width: 88) }
            }
            HStack(alignment: .top, spacing: 12) {
                formField(label: "Weight (lbs)") { TextField("0.0", text: $weightLbs).keyboardType(.decimalPad).brtrInputStyle() }
                formField(label: "Dimensions (in)") { TextField("L × W × H", text: $dimensions).brtrInputStyle() }
            }
            formField(label: "Delivery Method") {
                VStack(spacing: 8) {
                    ForEach(DeliveryMethod.allCases, id: \.self) { method in
                        checkboxRow(label: method.rawValue, isChecked: Binding(get: { deliveryMethods.contains(method) }, set: { if $0 { deliveryMethods.insert(method) } else { deliveryMethods.remove(method) } }))
                    }
                }
            }
            formField(label: "Packaging / Proof of Ownership") {
                VStack(spacing: 8) {
                    checkboxRow(label: "Original box included", isChecked: $hasOriginalBox)
                    checkboxRow(label: "Receipt / proof of purchase", isChecked: $hasReceipt)
                    checkboxRow(label: "Serial number available", isChecked: $hasSerialNumber)
                }
            }
        }
    }

    private var serviceFieldsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionDivider(label: "Service Info", icon: "wrench.and.screwdriver.fill")
            formField(label: "Scope of Work*") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(ServiceScope.allCases, id: \.self) { s in pillToggle(label: s.rawValue, isSelected: scope == s) { scope = (scope == s) ? nil : s } }
                }
            }
            formField(label: "Mode of Delivery*") {
                HStack(spacing: 8) {
                    ForEach(ServiceMode.allCases, id: \.self) { mode in pillToggle(label: mode.rawValue, isSelected: serviceMode == mode) { serviceMode = (serviceMode == mode) ? nil : mode } }
                }
            }
            formField(label: "Experience Level") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(ExperienceLevel.allCases, id: \.self) { level in pillToggle(label: level.rawValue, isSelected: experienceLevel == level) { experienceLevel = (experienceLevel == level) ? nil : level } }
                }
            }
            formField(label: "Available Days") {
                HStack(spacing: 5) {
                    ForEach(weekdays, id: \.self) { day in
                        let isSelected = availableDays.contains(day)
                        Button { if isSelected { availableDays.remove(day) } else { availableDays.insert(day) } } label: {
                            Text(day).font(.system(size: 11, weight: .semibold)).foregroundColor(isSelected ? .white : .brtrTextSecondary)
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(isSelected ? Color.brtrPurple : Color.brtrCard).cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.clear : Color.brtrBorder, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            formField(label: "Portfolio / Credentials") {
                HStack(spacing: 8) {
                    Image(systemName: "link").font(.system(size: 13)).foregroundColor(.brtrTextMuted)
                    TextField("github.com/you, behance.net/you...", text: $portfolioLink).font(.system(size: 15)).foregroundColor(.white).autocapitalization(.none).keyboardType(.URL)
                }
                .padding(14).background(Color.brtrCard).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
            }
            formField(label: "Tools / Materials from Other Party") { TextField("e.g. You provide the paint, I bring the brushes", text: $materialsNote).brtrInputStyle() }
        }
    }

    private var barterCoreSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionDivider(label: "Trade Terms", icon: "arrow.left.arrow.right")
            formField(label: "Estimated Market Value*") {
                HStack(spacing: 8) {
                    Text("$").font(.system(size: 17, weight: .semibold)).foregroundColor(.brtrTextMuted)
                    TextField("0", text: $estimatedValue).font(.system(size: 17)).foregroundColor(.white).keyboardType(.numberPad)
                }
                .padding(14).background(Color.brtrCard).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(!estimatedValue.isEmpty ? Color.brtrPurple.opacity(0.6) : Color.brtrBorder, lineWidth: 1))
            }
            formField(label: "Seeking In Return") { TextField("e.g. Photography session, iPad Pro, Logo design...", text: $seekingInReturn).brtrInputStyle() }
            formField(label: "Trade Flexibility") {
                VStack(spacing: 10) {
                    HStack {
                        Text("Firm").font(.system(size: 12)).foregroundColor(.brtrTextMuted)
                        Spacer()
                        Text(flexibilityLabel).font(.system(size: 13, weight: .semibold)).foregroundColor(.brtrPurpleLight)
                        Spacer()
                        Text("Flexible").font(.system(size: 12)).foregroundColor(.brtrTextMuted)
                    }
                    Slider(value: $tradeFlexibility, in: 0...100, step: 1).tint(Color.brtrPurple)
                }
                .padding(14).background(Color.brtrCard).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
            }
            formField(label: "Exchange Options") {
                HStack(spacing: 10) {
                    ForEach(ExchangeOption.allCases, id: \.self) { option in
                        let isOn = exchangeOptions.contains(option)
                        Button {
                            if isOn { if exchangeOptions.count > 1 { exchangeOptions.remove(option) } } else { exchangeOptions.insert(option) }
                        } label: {
                            Text(option.rawValue).font(.system(size: 14, weight: .semibold)).foregroundColor(isOn ? .white : .brtrTextSecondary)
                                .padding(.horizontal, 18).padding(.vertical, 10)
                                .background(isOn ? Color.brtrPurple : Color.brtrCard).cornerRadius(20)
                                .overlay(Capsule().stroke(isOn ? Color.clear : Color.brtrBorder, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            formField(label: "Zip Code") {
                HStack(spacing: 8) {
                    Image(systemName: "location").font(.system(size: 13)).foregroundColor(.brtrTextMuted)
                    TextField("e.g. 10001", text: $zipCode).font(.system(size: 15)).foregroundColor(.white).keyboardType(.numberPad)
                }
                .padding(14).background(Color.brtrCard).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
            }
            formField(label: "Barter Range") {
                VStack(spacing: 10) {
                    RangeSlider(range: $barterRange, bounds: 5...75)
                    HStack {
                        rangeLabel("\(Int(barterRange.lowerBound)) mi")
                        Spacer()
                        rangeLabel("\(Int(barterRange.upperBound)) mi")
                    }
                }
                .padding(14).background(Color.brtrCard).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
            }
        }
    }

    private func rangeLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 6).background(Color.brtrPurple).cornerRadius(20)
    }

    // MARK: - Publish Button

    private var publishButton: some View {
        Button {
            guard isFormValid else { return }
            Task {
                let imageData = selectedImages.first.flatMap { $0.jpegData(compressionQuality: 0.8) }
                await servicesManager.createService(
                    title: serviceName, description: description, category: selectedCategory.rawValue, imageData: imageData,
                    listingType: listingType == .product ? "product" : "service",
                    estimatedValue: estimatedValue.isEmpty ? nil : estimatedValue,
                    seekingInReturn: seekingInReturn.isEmpty ? nil : seekingInReturn,
                    tradeFlexibility: Int(tradeFlexibility),
                    exchangeOptions: exchangeOptions.map { $0.rawValue },
                    zipCode: zipCode.isEmpty ? nil : zipCode,
                    barterRangeMin: Int(barterRange.lowerBound), barterRangeMax: Int(barterRange.upperBound),
                    condition: condition?.rawValue, brand: brand.isEmpty ? nil : brand,
                    modelYear: modelYear.isEmpty ? nil : modelYear, weightLbs: weightLbs.isEmpty ? nil : weightLbs,
                    dimensions: dimensions.isEmpty ? nil : dimensions, deliveryMethods: deliveryMethods.map { $0.rawValue },
                    hasOriginalBox: hasOriginalBox, hasReceipt: hasReceipt, hasSerialNumber: hasSerialNumber,
                    scope: scope?.rawValue, serviceMode: serviceMode?.rawValue, experienceLevel: experienceLevel?.rawValue,
                    availableDays: Array(availableDays), portfolioLink: portfolioLink.isEmpty ? nil : portfolioLink,
                    materialsNote: materialsNote.isEmpty ? nil : materialsNote
                )
                if servicesManager.errorMessage == nil { dismiss() }
            }
        } label: {
            if servicesManager.isLoading {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black)).frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.white.opacity(0.6)).cornerRadius(14)
            } else {
                Text("Publish Listing").font(.system(size: 17, weight: .semibold)).foregroundColor(isFormValid ? .black : .white.opacity(0.4))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(isFormValid ? Color.white : Color.brtrCard).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(isFormValid ? Color.clear : Color.brtrBorder, lineWidth: 1))
            }
        }
        .disabled(!isFormValid || servicesManager.isLoading)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(.brtrTextSecondary)
            content()
        }
    }

    private func sectionDivider(label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color.brtrBorder).frame(height: 1)
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(.brtrPurpleLight)
                Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(.brtrPurpleLight).textCase(.uppercase).tracking(0.8)
            }
            .padding(.horizontal, 10).padding(.vertical, 5).background(Color.brtrPurpleDim.opacity(0.5)).cornerRadius(20)
            Rectangle().fill(Color.brtrBorder).frame(height: 1)
        }
    }

    private func pillToggle(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(isSelected ? .white : .brtrTextSecondary)
                .frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(isSelected ? Color.brtrPurple : Color.brtrCard).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : Color.brtrBorder, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func checkboxRow(label: String, isChecked: Binding<Bool>) -> some View {
        Button { isChecked.wrappedValue.toggle() } label: {
            HStack {
                Text(label).font(.system(size: 15)).foregroundColor(.white)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 5).fill(isChecked.wrappedValue ? Color.brtrPurple : Color.brtrCard).frame(width: 20, height: 20)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(isChecked.wrappedValue ? Color.clear : Color.brtrBorder, lineWidth: 1.5))
                    if isChecked.wrappedValue { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white) }
                }
            }
            .padding(14).background(Color.brtrCard).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Range Slider

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0

    init(range: Binding<ClosedRange<Double>>, bounds: ClosedRange<Double>) {
        self._range = range; self.bounds = bounds
        self._lowerValue = State(initialValue: range.wrappedValue.lowerBound)
        self._upperValue = State(initialValue: range.wrappedValue.upperBound)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.brtrTextMuted.opacity(0.3)).frame(height: 4)
                Rectangle().fill(Color.brtrPurple).frame(width: activeRangeWidth(in: geometry.size.width), height: 4).offset(x: lowerThumbOffset(in: geometry.size.width))
                Circle().fill(Color.brtrPurple).frame(width: 24, height: 24).overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(x: lowerThumbOffset(in: geometry.size.width) - 12)
                    .gesture(DragGesture().onChanged { value in
                        let percent = min(max(0, value.location.x / geometry.size.width), 1)
                        lowerValue = min(bounds.lowerBound + percent * (bounds.upperBound - bounds.lowerBound), upperValue - 5)
                        range = lowerValue...upperValue
                    })
                Circle().fill(Color.brtrPurple).frame(width: 24, height: 24).overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(x: upperThumbOffset(in: geometry.size.width) - 12)
                    .gesture(DragGesture().onChanged { value in
                        let percent = min(max(0, value.location.x / geometry.size.width), 1)
                        upperValue = max(bounds.lowerBound + percent * (bounds.upperBound - bounds.lowerBound), lowerValue + 5)
                        range = lowerValue...upperValue
                    })
            }
        }
        .frame(height: 24)
    }

    private func lowerThumbOffset(in width: CGFloat) -> CGFloat { (lowerValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound) * width }
    private func upperThumbOffset(in width: CGFloat) -> CGFloat { (upperValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound) * width }
    private func activeRangeWidth(in width: CGFloat) -> CGFloat {
        ((upperValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound) - (lowerValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * width
    }
}

// MARK: - Input Style Extension

extension View {
    func brtrInputStyle() -> some View {
        self.font(.system(size: 15)).foregroundColor(.white).padding(14).background(Color.brtrCard).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brtrBorder, lineWidth: 1))
    }
}
