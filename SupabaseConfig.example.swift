import Foundation
import Supabase

// MARK: - Supabase Configuration Template
// 1. Rename this file to "SupabaseConfig.swift"
// 2. Replace the placeholder values below with your actual Supabase credentials
// 3. You can find these at: https://app.supabase.com/project/_/settings/api

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
