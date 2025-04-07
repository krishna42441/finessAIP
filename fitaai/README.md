# FitAAI - AI-Powered Fitness Assistant

An intelligent fitness assistant that generates personalized workout and nutrition plans using AI.

## Features

- **AI-Generated Workout Plans**: Personalized plans based on fitness level, goals, and available equipment.
- **Nutrition Guidance**: Custom meal plans tailored to dietary preferences and restrictions.
- **Intelligent Chat Assistant**: Get answers to fitness questions and receive motivation from the AI coach.
- **Progress Tracking**: Monitor your fitness journey with built-in tracking tools.
- **Personalized Experience**: The app adapts to your feedback and progress over time.

## Tech Stack

- **Frontend**: Flutter for cross-platform mobile development
- **Backend**: Supabase for database, authentication, and storage
- **AI**: Google's Gemini API for generating personalized content
- **Caching**: Local caching for improved performance
- **Architecture**: Service-oriented architecture with clear separation of concerns

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- An IDE (VS Code, Android Studio, etc.)
- A Supabase account
- A Google AI API key

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/fitaai.git
   cd fitaai
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Create a `.env` file in the root directory based on `.env.example`:
   ```
   cp .env.example .env
   ```
   
4. Fill in your configuration values in the `.env` file.

5. Set up the database:
   - Log in to your Supabase dashboard
   - Navigate to the SQL Editor
   - Copy the contents of `lib/services/db_setup.sql`
   - Run the SQL script in the Supabase SQL Editor

6. Run the app:
   ```
   flutter run
   ```

## Database Setup

The app requires specific database functions and policies to be set up in Supabase:

1. **Admin Setup (one-time)**: 
   - Run the SQL from `getAdminSetupScript()` in `lib/services/setup_database.dart` in the Supabase SQL Editor

2. **Database Schema**:
   - Run the SQL script in `lib/services/db_setup.sql` to create:
     - The `run_sql` function for MCP integration
     - Row-level security policies for user data protection
     - Database indexes for query optimization
     - Helper functions for common operations

## Architecture

The app follows a layered architecture:

1. **UI Layer**: Flutter widgets and screens
2. **Service Layer**: Business logic and data processing
3. **Data Layer**: Models and data manipulation
4. **Database Layer**: Supabase integration and SQL operations

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
