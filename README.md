# Aera - A Flutter Messaging Application

> **A cross-platform messaging app for seamless communication across space and time.** 🚀

## 🌟 About Aera

Aera is a feature-rich Flutter-based messaging application that enables real-time communication between users. Built with modern technologies and a focus on user experience, Aera supports individual chats, group messaging, and AI-powered chatbot integration.

**Tagline:** *"Across Space & Time"* ✨

## ✨ Key Features

### 📱 Core Messaging
- **One-to-One Messaging**: Real-time direct messaging between users
- **Group Chat**: Create and manage group conversations with multiple members
- **Message Types**: Support for text and image messages
- **Message Status**: Track message delivery and read receipts
- **Message Management**: Delete messages for yourself or all users, clear chat history

### 🤖 AI Integration
- **Aurex AI Chatbot**: Integrated AI chatbot for intelligent conversations
- **Chatbot API**: Powered by Gemini API for advanced responses

### 👥 User Management
- **User Search**: Find and connect with other users
- **Contact Management**: Add, view, and manage contacts
- **User Profile**: Customizable user profiles with bio and profile pictures
- **Online Status**: See when contacts are online
- **Last Seen**: Track when users were last active

### 🔔 Notifications
- **Push Notifications**: Real-time notifications using Firebase Cloud Messaging (FCM)
- **Custom Notification Server**: Notification handling via custom backend

### 🎨 User Experience
- **Dark/Light Theme**: Toggle between dark and light modes
- **Lottie Animations**: Smooth animations for loading and interactions
- **Haptic Feedback**: Tactile feedback for user actions
- **Responsive Design**: Works seamlessly across different screen sizes

### 💾 Data Management
- **Local Storage**: Hive database for caching messages and offline access
- **Cloud Sync**: Supabase integration for real-time cloud synchronization

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter
- **Language**: Dart
- **UI Components**: 
  - Material Design
  - Google Fonts
  - Lottie Animations
  - Cached Network Image

### Backend & Database
- **Authentication**: Firebase Authentication
- **Real-time Database**: Supabase (PostgreSQL)
- **Cloud Storage**: Firebase Storage
- **Messaging**: Firebase Cloud Messaging (FCM)
- **AI Integration**: Gemini API

### Platform Support
- **Mobile**: iOS, Android
- **Desktop**: Windows, Linux, Web
- **Web**: Flutter Web

## 📦 Dependencies

```yaml
Core:
  - flutter
  - dart

Authentication & Backend:
  - firebase_auth
  - firebase_core
  - firebase_messaging
  - supabase_flutter
  - google_sign_in

UI & UX:
  - flutter/material
  - google_fonts
  - lottie
  - cached_network_image
  - flutter_speed_dial
  - flutter_slidable

Data Management:
  - hive
  - http

Other:
  - image_picker
  - permission_handler
  - audio_players
  - intl
  - media_scanner
  - flutter_launcher_icons
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Dart SDK
- Firebase Project Setup
- Supabase Project Setup
- Google Sign-In credentials

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/OnkarGaikwad-astro/Aera.git
cd Aera
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Configure Firebase:**
   - Set up Firebase project in Firebase Console
   - Download and configure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase options in `lib/firebase_options.dart`

4. **Configure Supabase:**
   - Set up Supabase project
   - Update Supabase URL and credentials in `lib/main.dart`:
   ```dart
   await Supabase.initialize(
     url: "your_supabase_url",
     anonKey: "your_supabase_key",
   );
   ```

5. **Run the app:**
```bash
# For development
flutter run

# For specific platform
flutter run -d android  # Android
flutter run -d ios      # iOS
flutter run -d windows  # Windows
flutter run -d linux    # Linux
flutter run -d web      # Web
```

## 📂 Project Structure

```
lib/
├── main.dart                 # App entry point
├── login_page.dart          # Authentication UI
├── home_page.dart           # Main chat list
├── chat_page.dart           # Individual chat screen
├── group_chat.dart          # Group chat screen
├── chatbot_page.dart        # AI chatbot interface
├── create_group.dart        # Group creation
├── add_contact.dart         # Contact management
├── essentials/
│   ├── functions.dart       # API and database operations
│   ├── colours.dart         # Theme colors
│   ├── data.dart            # Global data structures
│   └── slide.dart           # Custom animations
├── firebase_options.dart    # Firebase configuration
└── notifications.dart       # Notification handling
```

## 🔑 Key Classes & Functions

### SupabaseChatApi
Main API class for all database and messaging operations:
- `saveUser()` - Save/update user profile
- `addMessageFast()` - Send messages
- `create_group()` - Create group chats
- `getAllChatsFormatted()` - Fetch all conversations
- `searchUsers()` - Search for users
- `on_contacts()` - Get online status of contacts

### Message Features
- Message sending with text and image support
- Read receipts tracking
- Message deletion for individual users
- Group message handling with member tracking
- Message caching with Hive

## 🎨 Customization

### Theme Colors
Edit `lib/essentials/colours.dart` to customize the app theme.

### Animations
Lottie animations are stored in `assets/lotties/` directory. Replace with your own animations.

## 🔐 Security Considerations

- Use environment variables for sensitive credentials
- Enable Row Level Security (RLS) in Supabase
- Validate user input on both client and server
- Use HTTPS for all API calls
- Implement proper authentication flows

## 📝 API Reference

### User Management
- Create/Update User Profile
- Fetch User Information
- Search Users
- Get User Online Status

### Messaging
- Send Message
- Fetch Messages
- Mark Messages as Read
- Delete Messages
- Clear Chat History

### Groups
- Create Group
- Add Members to Group
- Remove Members from Group
- Group Message Management

## 🐛 Known Issues

- [Add any known issues here]

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👤 Author

**Onkar Gaikwad**
- GitHub: [@OnkarGaikwad-astro](https://github.com/OnkarGaikwad-astro)
- Repository: [Aera](https://github.com/OnkarGaikwad-astro/Aera)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for authentication and cloud services
- Supabase for real-time database solution
- All contributors and users for their support

## 📞 Support

For support, open an issue on GitHub or contact the developer.

---

**Across Space & Time** 🚀 - Connect with anyone, anywhere!
