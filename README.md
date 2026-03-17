# BRTR - Barter Trading App

A modern iOS app for bartering services built with SwiftUI and Supabase.

## Features

- 🔐 Authentication (Email/Password & Sign in with Apple)
- 📱 Service Listing & Discovery
- 🔍 Search & Category Filtering
- 💬 Real-time Messaging
- ⭐️ User Ratings & Reviews
- 📸 Image Upload Support
- 🎨 Beautiful Dark UI Design

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Supabase Account

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd BRTR
```

### 2. Install Dependencies

This project uses Swift Package Manager. Dependencies will be automatically resolved when you open the project in Xcode.

### 3. Configure Supabase

1. Create a new project at [Supabase](https://supabase.com)
2. Go to Project Settings → API
3. Copy your project URL and anon/public key
4. Open `SupabaseConfig.swift` and replace the placeholder values:

```swift
private let supabaseURL = URL(string: "https://your-project.supabase.co")!
private let supabaseKey = "your-anon-key"
```

### 4. Set Up Database Schema

Run these SQL commands in your Supabase SQL Editor:

```sql
-- Create users table
create table users (
  id uuid references auth.users primary key,
  username text unique not null,
  full_name text not null,
  bio text,
  avatar_url text,
  rating numeric default 0,
  review_count integer default 0,
  created_at timestamp with time zone default now()
);

-- Create services table
create table services (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references users(id) on delete cascade not null,
  title text not null,
  description text not null,
  category text not null,
  image_url text,
  is_active boolean default true,
  created_at timestamp with time zone default now()
);

-- Create barter_requests table
create table barter_requests (
  id uuid default gen_random_uuid() primary key,
  from_user_id uuid references users(id) on delete cascade not null,
  to_user_id uuid references users(id) on delete cascade not null,
  offered_service_id uuid references services(id) on delete cascade not null,
  requested_service_id uuid references services(id) on delete cascade not null,
  status text not null check (status in ('pending', 'accepted', 'declined', 'completed', 'cancelled')),
  message text,
  created_at timestamp with time zone default now()
);

-- Create messages table
create table messages (
  id uuid default gen_random_uuid() primary key,
  barter_id uuid references barter_requests(id) on delete cascade not null,
  sender_id uuid references users(id) on delete cascade not null,
  content text not null,
  is_read boolean default false,
  created_at timestamp with time zone default now()
);

-- Create reviews table
create table reviews (
  id uuid default gen_random_uuid() primary key,
  reviewer_id uuid references users(id) on delete cascade not null,
  reviewee_id uuid references users(id) on delete cascade not null,
  barter_id uuid references barter_requests(id) on delete cascade not null,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamp with time zone default now()
);

-- Enable Row Level Security
alter table users enable row level security;
alter table services enable row level security;
alter table barter_requests enable row level security;
alter table messages enable row level security;
alter table reviews enable row level security;

-- Create policies (example - adjust as needed)
create policy "Users can view all profiles" on users for select using (true);
create policy "Users can update own profile" on users for update using (auth.uid() = id);

create policy "Anyone can view active services" on services for select using (is_active = true);
create policy "Users can create own services" on services for insert with check (auth.uid() = user_id);
create policy "Users can update own services" on services for update using (auth.uid() = user_id);
create policy "Users can delete own services" on services for delete using (auth.uid() = user_id);
```

### 5. Create Storage Bucket

1. Go to Storage in your Supabase dashboard
2. Create a new bucket named `service-images`
3. Set it to Public
4. Configure upload policies as needed

### 6. Build and Run

1. Open the project in Xcode
2. Select a simulator or device
3. Press ⌘R to build and run

## Project Structure

```
BRTR/
├── Models.swift              # Data models
├── SupabaseConfig.swift      # Supabase configuration
├── Managers/
│   ├── AuthManager.swift
│   ├── ServicesManager.swift
│   ├── BarterManager.swift
│   └── MessagingManager.swift
├── Views/
│   ├── HomeView.swift
│   ├── ServiceDetailView.swift
│   ├── OtherViews.swift      # Tab views & other UI
│   └── SplashView.swift
└── DesignSystem.swift        # Colors, fonts, components

## Security Notes

⚠️ **IMPORTANT**: Before pushing to GitHub:

1. Make sure you've replaced the placeholder values in `SupabaseConfig.swift` with your actual credentials
2. Consider uncommenting the line in `.gitignore` to exclude `SupabaseConfig.swift` from version control
3. If you've already committed your credentials, rotate your keys immediately in the Supabase dashboard

## Contributing

This is a personal project, but suggestions and feedback are welcome!

## License

[Add your license here]
