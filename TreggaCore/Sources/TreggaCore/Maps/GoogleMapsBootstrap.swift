import Foundation
import TreggaCore
import GoogleMaps

public enum GoogleMapsBootstrap {
    public static func configure() {
        GMSServices.provideAPIKey(Config.GOOGLE_MAPS_API_KEY)
    }
}
