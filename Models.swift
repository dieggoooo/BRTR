import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var username: String
    var fullName: String
    var bio: String?
    var avatarUrl: String?
    var rating: Double
    var reviewCount: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case bio
        case avatarUrl = "avatar_url"
        case rating
        case reviewCount = "review_count"
        case createdAt = "created_at"
    }
}

// MARK: - Service
struct Service: Codable, Identifiable {    let id: UUID
    var userId: UUID
    var title: String
    var description: String
    var category: String
    var imageUrl: String?
    var isActive: Bool
    var createdAt: Date
    var user: UserProfile?

    // Shared trade fields
    var listingType: String?
    var estimatedValue: String?
    var seekingInReturn: String?
    var tradeFlexibility: Int?
    var exchangeOptions: [String]?
    var zipCode: String?
    var barterRangeMin: Int?
    var barterRangeMax: Int?

    // Product fields
    var condition: String?
    var brand: String?
    var modelYear: String?
    var weightLbs: String?
    var dimensions: String?
    var deliveryMethods: [String]?
    var hasOriginalBox: Bool?
    var hasReceipt: Bool?
    var hasSerialNumber: Bool?

    // Service fields
    var scope: String?
    var serviceMode: String?
    var experienceLevel: String?
    var availableDays: [String]?
    var portfolioLink: String?
    var materialsNote: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case imageUrl = "image_url"
        case isActive = "is_active"
        case createdAt = "created_at"
        case user = "users"
        case listingType = "listing_type"
        case estimatedValue = "estimated_value"
        case seekingInReturn = "seeking_in_return"
        case tradeFlexibility = "trade_flexibility"
        case exchangeOptions = "exchange_options"
        case zipCode = "zip_code"
        case barterRangeMin = "barter_range_min"
        case barterRangeMax = "barter_range_max"
        case condition
        case brand
        case modelYear = "model_year"
        case weightLbs = "weight_lbs"
        case dimensions
        case deliveryMethods = "delivery_methods"
        case hasOriginalBox = "has_original_box"
        case hasReceipt = "has_receipt"
        case hasSerialNumber = "has_serial_number"
        case scope
        case serviceMode = "service_mode"
        case experienceLevel = "experience_level"
        case availableDays = "available_days"
        case portfolioLink = "portfolio_link"
        case materialsNote = "materials_note"
    }
}

// MARK: - Barter Request
struct BarterRequest: Codable, Identifiable {
    let id: UUID
    var fromUserId: UUID
    var toUserId: UUID
    var offeredServiceId: UUID
    var requestedServiceId: UUID
    var status: BarterStatus
    var message: String?
    var createdAt: Date
    var fromUser: UserProfile?
    var toUser: UserProfile?
    var offeredService: Service?
    var requestedService: Service?

    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case offeredServiceId = "offered_service_id"
        case requestedServiceId = "requested_service_id"
        case status
        case message
        case createdAt = "created_at"
        case fromUser = "from_user"
        case toUser = "to_user"
        case offeredService = "offered_service"
        case requestedService = "requested_service"
    }
}

enum BarterStatus: String, Codable {
    case pending
    case accepted
    case declined
    case completed
    case cancelled
}

// MARK: - Message
struct Message: Codable, Identifiable {
    let id: UUID
    var barterId: UUID
    var senderId: UUID
    var content: String
    var isRead: Bool
    var createdAt: Date
    var sender: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case barterId = "barter_id"
        case senderId = "sender_id"
        case content
        case isRead = "is_read"
        case createdAt = "created_at"
        case sender
    }
}

// MARK: - Review
struct Review: Codable, Identifiable {
    let id: UUID
    var reviewerId: UUID
    var revieweeId: UUID
    var barterId: UUID
    var rating: Int
    var comment: String?
    var createdAt: Date
    var reviewer: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case reviewerId = "reviewer_id"
        case revieweeId = "reviewee_id"
        case barterId = "barter_id"
        case rating
        case comment
        case createdAt = "created_at"
        case reviewer
    }
}

// MARK: - Service Category
enum ServiceCategory: String, CaseIterable, Codable {
    case all = "All"
    case design = "Design"
    case development = "Development"
    case marketing = "Marketing"
    case writing = "Writing"
    case photography = "Photography"
    case music = "Music"
    case fitness = "Fitness"
    case cooking = "Cooking"
    case tutoring = "Tutoring"
    case other = "Other"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .design: return "paintbrush.fill"
        case .development: return "chevron.left.forwardslash.chevron.right"
        case .marketing: return "megaphone.fill"
        case .writing: return "pencil"
        case .photography: return "camera.fill"
        case .music: return "music.note"
        case .fitness: return "figure.run"
        case .cooking: return "fork.knife"
        case .tutoring: return "book.fill"
        case .other: return "star.fill"
        }
    }
}

// MARK: - Service Extensions for UI
extension Service {
    var serviceCategory: ServiceCategory {
        ServiceCategory(rawValue: self.category) ?? .other
    }

    var owner: UserProfile {
        user ?? UserProfile(
            id: userId,
            username: "Unknown",
            fullName: "Unknown User",
            bio: nil,
            avatarUrl: nil,
            rating: 0,
            reviewCount: 0,
            createdAt: Date()
        )
    }

    var availability: String { "Available Now" }

    var displayEstimatedValue: String {
        if let val = estimatedValue, !val.isEmpty { return "$\(val)" }
        return "Value not set"
    }

    var isProduct: Bool {
        listingType == "product"
    }

    var flexibilityLabel: String {
        switch tradeFlexibility ?? 65 {
        case 0..<20:  return "Firm on terms"
        case 20..<40: return "Mostly firm"
        case 40..<60: return "Open to offers"
        case 60..<80: return "Very flexible"
        default:       return "Any offer welcome"
        }
    }
}

// MARK: - UserProfile Extensions for UI
extension UserProfile {
    var name: String { fullName }
    var isVerified: Bool { rating >= 4.5 }
    var completedTrades: Int { reviewCount }
}
