import Foundation

public enum MapStyle {
    /// JSON style for light mode. Reduces clutter, mantiene paleta cercana a Tregga.
    public static let light = """
    [
      {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
      {"featureType":"transit","stylers":[{"visibility":"off"}]}
    ]
    """

    public static let dark = """
    [
      {"elementType":"geometry","stylers":[{"color":"#1f2421"}]},
      {"elementType":"labels.text.fill","stylers":[{"color":"#a6afa8"}]},
      {"elementType":"labels.text.stroke","stylers":[{"color":"#1f2421"}]},
      {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
      {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1b231d"}]},
      {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8fa5a3"}]},
      {"featureType":"transit","stylers":[{"visibility":"off"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1612"}]}
    ]
    """
}
