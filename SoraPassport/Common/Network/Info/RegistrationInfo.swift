import Foundation

struct RegistrationUserInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        case country
    }

    var firstName: String
    var lastName: String
    var country: String
}

struct RegistrationInfo: Codable {
    var userData: RegistrationUserInfo
    var invitationCode: String?
}
