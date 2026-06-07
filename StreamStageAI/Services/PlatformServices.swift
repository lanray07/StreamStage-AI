import Foundation
import Observation
import StoreKit
import UserNotifications

@MainActor
@Observable
final class SubscriptionService {
    var products: [Product] = []
    var currentPlan: SubscriptionPlan = .free
    var isActive = false
    var isLoading = false
    var statusMessage = "Free plan"
    var errorMessage: String?

    private let productIDs = [
        "com.streamstage.creatorpro.monthly",
        "com.streamstage.creatorpro.yearly",
        "com.streamstage.streamelite.monthly"
    ]

    func loadProducts() async {
        guard products.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            await refreshEntitlements()
        } catch {
            errorMessage = "StoreKit products are using placeholders until App Store Connect is configured."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                statusMessage = "Purchase pending"
            case .userCancelled:
                statusMessage = "Purchase cancelled"
            @unknown default:
                statusMessage = "Purchase status unavailable"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var detectedPlan: SubscriptionPlan = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.productID.contains("streamelite") {
                detectedPlan = .streamElite
            } else if transaction.productID.contains("creatorpro") && detectedPlan != .streamElite {
                detectedPlan = .creatorPro
            }
        }

        currentPlan = detectedPlan
        isActive = detectedPlan != .free
        statusMessage = isActive ? "\(detectedPlan.rawValue) active" : "Free plan"
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StreamStageServiceError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

@MainActor
@Observable
final class LocalNotificationService {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var errorMessage: String?

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func schedulePracticeReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "StreamStage rehearsal"
        content.body = "Step on stage before the world sees you."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86_400, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-practice-reminder", content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
