import Foundation
import Supabase

// MARK: - Supabase Configuration
// Replace these with your actual Supabase project URL and anon key
private let supabaseURL = URL(string: "YOUR_SUPABASE_PROJECT_URL")!
private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"

// MARK: - Global Supabase Client
let supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: supabaseKey,
    options: .init(
        auth: .init(
            flowType: .pkce
        )
    )
)
