import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var startupViewModel = AppStartupViewModel()

    var body: some View {
        ContentView(viewModel: contentViewModel)
            .task {
                await startupViewModel.bootstrap(
                    modelContext: modelContext, contentViewModel: contentViewModel)
            }
    }
}
