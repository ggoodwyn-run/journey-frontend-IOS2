import SwiftUI

// MARK: - Color Scheme (Modern Dark Blue - Cohesive & Harmonious)
struct JourneyColors {
    // Primary - vibrant but not harsh, works great on dark backgrounds
    static let primary = Color(red: 0.45, green: 0.75, blue: 0.95) // Vivid sky blue
    static let secondary = Color(red: 0.60, green: 0.85, blue: 1.0) // Bright cyan accent
    
    // Accent - complementary, used sparingly
    static let accent = Color(red: 0.95, green: 0.45, blue: 0.45) // Soft red (less orange clash)
    static let success = Color(red: 0.45, green: 0.85, blue: 0.65) // Teal success color
    
    // Background - clean dark professional look
    static let background = Color(red: 0.09, green: 0.13, blue: 0.22) // Deep navy base
    static let cardBackground = Color(red: 0.14, green: 0.18, blue: 0.28) // Slightly lighter cards
    
    // Text - maximum readability on dark backgrounds
    static let textPrimary = Color(red: 0.97, green: 0.98, blue: 1.0) // Pure white
    static let textSecondary = Color(red: 0.75, green: 0.80, blue: 0.90) // Light gray-blue
    static let textTertiary = Color(red: 0.60, green: 0.65, blue: 0.78) // Medium gray-blue
}
