import SwiftUI

final class AppState: ObservableObject {
    @AppStorage("isCalibrated")  var isCalibrated: Bool = false
    @Published var rollBias:  Double = 0        // °   saved at calibration
    @Published var pitchBias: Double = 0
    @Published var speedLimitMPH: Double?       // pulled from an API later
}
