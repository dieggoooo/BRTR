# ✅ Pre-Push Checklist

Before you push your code to GitHub, make sure you complete these steps:

## 🔒 Security (CRITICAL)

- [ ] **Replace placeholder credentials in `SupabaseConfig.swift`**
  - Replace `YOUR_SUPABASE_PROJECT_URL` with your actual Supabase URL
  - Replace `YOUR_SUPABASE_ANON_KEY` with your actual anon key
  
- [ ] **Decide on credential security strategy**
  - Option A: Keep credentials in code but add `SupabaseConfig.swift` to `.gitignore` (recommended for personal projects)
  - Option B: Use environment variables (recommended for team projects)
  - Option C: Use a separate config file that's ignored by git

## 🧹 Cleanup

- [ ] **Remove duplicate files**
  - Delete `SupabaseClient 2.swift` (use `SupabaseConfig.swift` instead)
  - Make sure there's only ONE file declaring the `supabase` client

- [ ] **Test the app**
  - [ ] Build succeeds without errors
  - [ ] Sign up/Sign in works
  - [ ] Can create a service
  - [ ] Can view services
  - [ ] Can navigate between tabs

## 📦 Dependencies

- [ ] **Ensure Supabase package is properly added**
  - In Xcode: File → Add Package Dependencies
  - URL: `https://github.com/supabase/supabase-swift`
  - Version: Latest stable release

## 📝 Documentation

- [ ] **Update README.md**
  - Add your repository URL
  - Add screenshots (optional but nice)
  - Add your license
  - Update any project-specific details

- [ ] **Create a LICENSE file** (if open source)
  - Choose a license: https://choosealicense.com/

## 🗄️ Database

- [ ] **Set up Supabase database**
  - Run all SQL migrations from README.md
  - Create storage bucket `service-images`
  - Configure Row Level Security policies
  - Test database connection

## 🚀 Git Setup

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Check what will be committed (make sure SupabaseConfig.swift has real values or is ignored)
git status

# Commit
git commit -m "Initial commit"

# Add remote
git remote add origin <your-github-repo-url>

# Push
git push -u origin main
```

## ⚠️ If You Accidentally Pushed Credentials

If you accidentally pushed your Supabase credentials to GitHub:

1. **Immediately rotate your keys** in Supabase dashboard (Settings → API)
2. Remove the credentials from git history:
   ```bash
   # Install BFG Repo-Cleaner or use git-filter-repo
   git filter-repo --path SupabaseConfig.swift --invert-paths
   git push --force
   ```
3. Update your local `SupabaseConfig.swift` with new keys
4. Add the file to `.gitignore` before committing again

## 📱 App Store Preparation (Future)

- [ ] Add app icons
- [ ] Add launch screen
- [ ] Update bundle identifier
- [ ] Configure signing & capabilities
- [ ] Add privacy policy
- [ ] Add terms of service

---

## Quick Command to Check Before Pushing

```bash
# See what will be committed
git diff --cached

# Search for placeholder text
grep -r "YOUR_SUPABASE" .

# Check if SupabaseConfig.swift will be committed
git ls-files | grep SupabaseConfig
```

If the grep finds "YOUR_SUPABASE", you need to replace those values!
