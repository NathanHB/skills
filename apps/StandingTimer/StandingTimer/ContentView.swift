import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.phase.label)
                .font(.headline)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)

            Button("Reset") { viewModel.reset() }
                .buttonStyle(.borderless)
        }
        .padding()
        .frame(width: 200)
    }
}
