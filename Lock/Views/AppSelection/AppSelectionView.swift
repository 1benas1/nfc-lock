import FamilyControls
import SwiftUI

struct AppSelectionView: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool

    var body: some View {
        Color.clear
            .familyActivityPicker(isPresented: $isPresented, selection: $selection)
    }
}
