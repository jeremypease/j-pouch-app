import SwiftUI

struct OnboardingView: View {
    let onComplete: (Stage) -> Void

    @State private var selectedStage: Stage = .adaptation

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Welcome to J-Pouch")
                        .font(.largeTitle.bold())
                    Text("Tell us where you are in your journey so we only ask you about what's relevant right now.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    ForEach(Stage.allCases) { stage in
                        Button {
                            selectedStage = stage
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stage.displayName)
                                        .font(.headline)
                                    Text(stage.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                if selectedStage == stage {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    onComplete(selectedStage)
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: { _ in })
}
