import Foundation
import Supabase

// MARK: - Supabase Configuration
// TODO: Replace these with your actual Supabase project credentials
// You can find these in your Supabase project settings: https://app.supabase.com
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
