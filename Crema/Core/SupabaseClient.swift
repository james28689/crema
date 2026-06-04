//
//  SupabaseClient.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import Foundation
import Supabase

// ─── Replace these two values with your project's URL and anon key ──────────
// Find them in the Supabase dashboard → Project Settings → API
private let supabaseURL  = "https://tktmdphrjcjgwtfactux.supabase.co"
private let supabaseKey  = "sb_publishable_O_EdJYeWA-68y7ljcKRBgg_pOY2AxJl"
// ─────────────────────────────────────────────────────────────────────────────

let supabase = SupabaseClient(
    supabaseURL: URL(string: supabaseURL)!,
    supabaseKey: supabaseKey
)
