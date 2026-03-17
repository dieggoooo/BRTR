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
struct Service: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var title: String
    var description: String
    var category: String
    var imageUrl: String?
    var isActive: Bool
    var createdAt: Date
    var user: UserProfile?

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
    
    var availability: String {
        "Available Now"
    }
    
    var estimatedValue: String {
        "$100-$500"
    }
}

// MARK: - UserProfile Extensions for UI
extension UserProfile {
    var name: String {
        fullName
    }
    
    var isVerified: Bool {
        rating >= 4.5
    }
    
    var completedTrades: Int {
        reviewCount
    }
}

