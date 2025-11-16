# CompostKaki Flutter Mobile App

A Flutter mobile application for the CompostKaki community composting platform.

## Features

- 🔐 **Authentication** - Email/password sign up and sign in
- 📱 **Journal Tab** - View and manage your compost bins
- 👥 **Community Tab** - View and accept community tasks
- 🪴 **Bin Management** - Create, join, and view compost bins
- 📝 **Activity Logging** - Log composting activities (materials, temperature, moisture, etc.)
- 📸 **Photo Upload** - Add photos to activity logs
- 📊 **Health Tracking** - Monitor bin health status and statistics
- 💪 **Task System** - Post and accept help requests

## Setup Instructions

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Supabase account and project

### Installation

1. **Navigate to the Flutter directory:**
   ```bash
   cd flutter
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase:**
   - Open `lib/main.dart`
   - Replace `YOUR_SUPABASE_URL` with your Supabase project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your Supabase anon key
   
   You can find these in your Supabase project settings under API.

4. **Run the app:**
   ```bash
   flutter run
   ```

### Project Structure

```
flutter/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── router/
│   │   └── app_router.dart      # Navigation routing
│   ├── services/
│   │   ├── auth_service.dart     # Authentication service
│   │   ├── bin_service.dart     # Bin management service
│   │   ├── task_service.dart    # Task management service
│   │   └── supabase_service.dart # Supabase client wrapper
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── main/
│   │   │   └── main_screen.dart
│   │   ├── bin/
│   │   │   ├── bin_detail_screen.dart
│   │   │   ├── add_bin_screen.dart
│   │   │   └── log_activity_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   ├── widgets/
│   │   ├── bin_card.dart
│   │   ├── task_card.dart
│   │   └── activity_timeline_item.dart
│   └── theme/
│       └── app_theme.dart        # App theme and colors
├── pubspec.yaml                  # Dependencies
└── README.md
```

## Key Dependencies

- `supabase_flutter` - Supabase client for backend
- `go_router` - Navigation routing
- `provider` - State management
- `image_picker` - Image selection
- `cached_network_image` - Image caching
- `qr_code_scanner` - QR code scanning (for future use)

## Development Notes

### Authentication Flow

1. User enters email
2. App checks if email exists
3. If exists → show password field → sign in
4. If not → redirect to signup

### Bin Management

- Users can create bins (become owner)
- Users can join bins via bin ID or URL
- Bin owners can delete bins
- All members can view bin details and log activities

### Activity Logging

Activities can be:
- **Add Materials** - Requires greens, browns, and water checkboxes
- **Add Water** - Simple water addition
- **Turn Pile** - Increments flip counter
- **Monitor** - Requires temperature and moisture input

### Task System

- Users can post help requests for their bins
- Tasks have urgency levels (High Priority, Normal, Low Priority)
- Tasks can be accepted and completed by community members
- Task creators can delete their own tasks

## Future Enhancements

- [ ] QR code scanner for joining bins
- [ ] Push notifications for task updates
- [ ] Image upload to Supabase storage
- [ ] Offline support
- [ ] Dark mode
- [ ] Profile editing
- [ ] Bin sharing via QR codes

## Troubleshooting

### Supabase Connection Issues
- Verify your Supabase URL and anon key are correct
- Check that your Supabase project is active
- Ensure your Supabase project has the required tables (bins, bin_logs, tasks, profiles, bin_members)

### Build Issues
- Run `flutter clean` and then `flutter pub get`
- Ensure you're using Flutter 3.0.0 or higher
- Check that all dependencies are compatible

## License

MIT License - same as the main CompostKaki project

