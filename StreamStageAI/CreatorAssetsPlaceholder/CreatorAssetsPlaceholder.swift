import SwiftUI

struct CreatorAssetPlaceholder: Identifiable {
    let id = UUID()
    var title: String
    var systemImage: String
    var tint: Color
}

enum CreatorAssetsPlaceholderLibrary {
    static let assets: [CreatorAssetPlaceholder] = [
        CreatorAssetPlaceholder(title: "Creator studio", systemImage: "video.fill", tint: .stagePurple),
        CreatorAssetPlaceholder(title: "Sales live", systemImage: "bag.fill", tint: .stagePink),
        CreatorAssetPlaceholder(title: "Gaming stream", systemImage: "gamecontroller.fill", tint: .stageBlue),
        CreatorAssetPlaceholder(title: "Coaching room", systemImage: "person.2.wave.2.fill", tint: .stageMint),
        CreatorAssetPlaceholder(title: "Founder demo", systemImage: "macwindow", tint: .stageAmber)
    ]
}
