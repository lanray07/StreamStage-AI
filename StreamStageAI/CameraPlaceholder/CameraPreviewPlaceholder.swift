import SwiftUI

struct CameraPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black)

            LinearGradient(
                colors: [
                    Color.stagePurple.opacity(0.54),
                    Color.black.opacity(0.92),
                    Color.stageBlue.opacity(0.48)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 94, height: 94)
                    Image(systemName: "person.crop.rectangle.stack")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.86))
                }

                VStack(spacing: 5) {
                    Text("Camera preview placeholder")
                        .font(.headline)
                    Text("Private rehearsal studio")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Preview")
                    Spacer()
                    Image(systemName: "lock.fill")
                }
                .font(.caption.weight(.semibold))
                .padding(12)
                .foregroundStyle(.white.opacity(0.82))

                Spacer()
            }
        }
        .aspectRatio(9 / 13, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
