## DevDeck

# DevDeck is a next-generation Project Management Portal designed to gamify the developer experience.
It bridges the gap between utility and showcase by transforming your code repositories into living digital assets.

Built with Flutter and powered by a robust hybrid backend (Firebase + Supabase), DevDeck provides a seamless ecosystem where project milestones translate into visual rewards.

## Snapshots

(Place screenshots of your app here)

Login Screen

Global Feed

Project Minting

Real-time Chat

## The DevDeck Card System: Evolution & Rarity

At the heart of DevDeck is the Dynamic Card Engine.
Unlike static portfolios, projects in DevDeck are minted as cards that evolve based on:

# Activity

# Commits

# Community Engagement

# 🔄 The 3 Tiers of Evolution

Your project card changes color and visual style as it levels up.

# ⚪ Common (Grey)

Level: Starter (0 – 10 Boosts)

Description:
The foundation. Every new project begins here as a standard entry in the deck.

# 🔵 Rare (Blue)

Level: Established (11 – 50 Boosts)

Description:
Achieved by consistent updates and document uploads.
The card gains a neon-blue glow, signifying an active and healthy project.

# 🟡 Mythic / Legendary (Gold)

Level: Masterpiece (50+ Boosts)

# Description:
The elite tier. Projects with high community engagement and completion status turn Gold and stand out in the Global Feed with special particle effects.

# 📈 How Levels Work

Levels are determined by XP (Experience Points) generated through Boosts:

Minting: +10 Boosts

Uploading Files: +5 Boosts per resource

Community Likes: +1 Boost per like

Updates: +2 Boosts per log entry

## 🧠 Core Workflow (3-Level Architecture)

DevDeck follows a streamlined three-tier architecture for performance, scalability, and security.

# 🎨 Level 1: Presentation Layer (Flutter UI)

Interface:
A responsive, glassmorphic UI built with Flutter that acts as the user’s Deck.

Role:
Handles user interactions, animations, and local state management.
Renders digital cards and provides the canvas for project minting.

# 🛡️ Level 2: Logic & Security Layer (Middleware)

The Guard:
Firebase Authentication manages identity verification and sessions.

Role:
Ensures only authorized Operators can mint cards or access private chats.
Bridges frontend actions with backend permissions using Row-Level Security (RLS).

# 🗄️ Level 3: Data & Storage Layer (Backend)

# The Vault:
Hybrid cloud infrastructure using Supabase + Firebase.

# Role:

Database: User profiles, card metadata, chat history

Storage: Project images, ZIPs, documentation

Real-time Sync: Instant updates to Global Feed and Chat

## ✨ Key Features
# 🚀 1. Project Management Portal

Centralized Hub: Manage all development ideas in one secure terminal

Resource Locker: Attach PDFs, ZIPs, and docs to project cards

Timeline Tracking: Visual history of project growth

# 🛡️ 2. Secure Hybrid Authentication

Firebase Auth: Email/password login with secure sessions

Seamless Sync: Profiles synced instantly with Supabase

Privacy First: RLS ensures controlled data access

# 🌍 3. Global Developer Feed

Real-time Timeline: Live project minting updates

Engagement: Like projects and download resources

Smart Filtering: View latest and most popular cards

# 💬 4. Real-Time Chat System

Global Dev Chat: Instant community interaction

Rich Messaging: Text and image support

Live Updates: Powered by Cloud Firestore

# 🎨 5. Modern Glassmorphic UI

Dark Theme: Sleek glassmorphism design

Responsive: Optimized across devices

Animations: Smooth transitions using flutter_animate

## 🛠️ Tech Stack

# Frontend: Flutter (Dart)

# Authentication: Firebase Auth

# Database: Cloud Firestore (NoSQL), Supabase (PostgreSQL)

# Storage: Firebase Storage, Supabase Storage

# State Management: setState, StreamBuilder

## 🚀 Getting Started
✅ Prerequisites

Flutter SDK

Dart SDK (included with Flutter)

Firebase Account

Supabase Account

📥 Installation
Clone the Repository
git clone https://github.com/your-username/devdeck.git
cd devdeck

Install Dependencies
flutter pub get

🔐 Configure Firebase

Create a project in Firebase Console

Enable Email/Password Authentication

Enable Firestore Database and Storage

Download google-services.json

Place it in android/app/

(For Web) Update Firebase Web Config in lib/main.dart

🧩 Configure Supabase

Create a project in Supabase Dashboard

Create public buckets:

images

files

Update:

lib/services/auth_service.dart


with your Supabase URL and Anon Key

▶️ Run the App
flutter run

📂 Project Structure
lib/
├── main.dart               # App entry point
├── theme.dart              # Global styles & colors
├── card.dart               # Digital card logic
├── pages/
│   ├── login_page.dart
│   ├── feed_page.dart
│   ├── upload_page.dart
│   ├── chat_page.dart
│   └── project_detail.dart
assets/
├── logo.png
└── intro.mp4

🤝 Contributing

Contributions are welcome!

Fork the Project

Create your Feature Branch

git checkout -b feature/AmazingFeature


Commit your Changes

git commit -m "Add AmazingFeature"


Push to Branch

git push origin feature/AmazingFeature


Open a Pull Request

📄 License

Distributed under the MIT License.
See LICENSE for more information.

📞 Contact

For inquiries or collaboration, reach out via LinkedIn.
