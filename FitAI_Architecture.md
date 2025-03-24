# FitAI Architecture Documentation

## Overview

FitAI is an AI-powered fitness and nutrition app designed to help users achieve their health goals through personalized plans, advanced tracking, and intelligent assistance. The application leverages artificial intelligence to deliver tailored fitness and nutrition experiences, adapting to users' needs, preferences, and progress.

This document outlines the complete architecture for developing FitAI using Flutter, Supabase, n8n for specialized AI workflows, and Google's Gemini AI for on-device and direct AI capabilities.

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Frontend Architecture (Flutter)](#frontend-architecture-flutter)
3. [Backend Architecture (Supabase)](#backend-architecture-supabase)
4. [AI Architecture (Hybrid Approach)](#ai-architecture-hybrid-approach)
5. [Integration Architecture](#integration-architecture)
6. [User Flows](#user-flows)
7. [Development Strategy](#development-strategy)
8. [Future Expansion](#future-expansion)

## System Architecture

FitAI utilizes a modern architecture integrating Flutter with Gemini AI, Supabase, and n8n:

```
┌─────────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│                     │       │                 │       │                 │
│  Flutter App        │◄─────►│    Supabase     │◄─────►│  n8n Workflows  │
│  (Frontend)         │       │    (Backend)    │       │  (Plan Generation)│
│  + Gemini AI        │       │                 │       │                 │
│  (Image & Chat)     │       │                 │       │                 │
└─────────────────────┘       └─────────────────┘       └─────────────────┘
        │                                                       ▲
        │                                                       │
        ▼                                                       ▼
┌─────────────────┐                                     ┌─────────────────┐
│  Gemini API     │                                     │  OpenAI API     │
│  (Google)       │                                     │  (Workout/      │
│                 │                                     │   Nutrition)    │
└─────────────────┘                                     └─────────────────┘
```

### Key Components:

1. **Flutter Mobile App with Gemini**: Cross-platform client application with Material 3 design, with embedded Gemini AI for image recognition and chat
2. **Supabase**: Backend-as-a-service for authentication, database, storage, and real-time updates
3. **n8n**: Workflow automation platform for specialized AI processing (workout and nutrition planning)
4. **External AI Services**: Gemini API for on-device AI tasks and OpenAI for specialized functions

## Frontend Architecture (Flutter)

The Flutter app will implement a clean architecture pattern with Material 3 design system.

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer                                          │
│ ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│ │  Screens    │    │  Widgets    │    │  Theme      │      │
│ └─────────────┘    └─────────────┘    └─────────────┘      │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Business Logic Layer                                        │
│ ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│ │  Bloc/      │    │  Services   │    │  Utilities  │      │
│ │  Providers  │    │             │    │             │      │
│ └─────────────┘    └─────────────┘    └─────────────┘      │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Data Layer                                                  │
│ ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│ │ Repositories│    │  Models     │    │Data Sources │      │
│ └─────────────┘    └─────────────┘    └─────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Main Screens & Navigation

FitAI features a clean, intuitive design with a bottom navigation bar as the primary way to access its core sections:

1. **Home Screen (Dashboard)**
   - Daily progress overview
   - Upcoming tasks
   - Quick-action buttons
   - Widgets for key metrics

2. **Workouts**
   - AI-generated workout plans
   - Weekly schedule view
   - Exercise details with instructions
   - Equipment requirements

3. **Nutrition**
   - AI-generated nutrition targets (macros/micros)
   - Food logging with image recognition
   - Daily and weekly nutritional summaries
   - Progress toward goals

4. **Progress**
   - Weight tracking
   - Body measurements
   - Visualizations and trends
   - AI-generated insights

5. **Chat (AI Assistant)**
   - Conversational interface
   - Context-aware responses
   - Plan adjustment requests
   - General fitness/nutrition advice

Additional navigation:
- **Side Drawer**: Profile, Settings, Help, Logout
- **App Bar**: Context-specific actions per screen

### UI Design

- Material 3 design implementation with dark theme
- Card-based widgets for data visualization
- Custom charts and progress indicators
- Responsive layouts for different screen sizes

### State Management

- **Flutter Bloc/Riverpod**: For predictable state management
- **Repository Pattern**: For data access abstraction
- **Service Locator Pattern**: For dependency injection

## Detailed UI/UX Specifications

This section details the complete UI/UX specifications for each screen, including layout, features, components, data displayed, and navigation patterns.

### 1. Onboarding Screens

#### 1.1 Welcome Screen
- **UI Components:**
  - Large app logo and branding
  - Animated welcome message
  - "Get Started" primary button
  - "Already have an account? Sign In" text button
- **Features:**
  - App introduction animation
  - Quick overview of app benefits (scrollable cards)
- **Navigation:**
  - "Get Started" → Account Creation
  - "Sign In" → Login Screen

#### 1.2 Account Creation Screen
- **UI Components:**
  - Email field with validation
  - Password field with strength indicator
  - Confirm password field
  - Social login buttons (Google, Apple)
  - Privacy policy and terms checkbox
  - "Create Account" button
- **Features:**
  - Real-time email validation
  - Password strength visualization
  - Error messaging for invalid inputs
- **Navigation:**
  - "Create Account" → Profile Setup
  - Back button → Welcome Screen

#### 1.3 Profile Setup Screens (Multi-step)
- **UI Components:**
  - Progress indicator showing completion steps
  - Form fields for each data point
  - Next/Back navigation buttons
  - Skip option for non-essential information
- **Features:**
  - Step 1: Basic Information
    - Name, age, gender, height, current weight
  - Step 2: Fitness Background
    - Current activity level
    - Previous exercise experience
    - Fitness level self-assessment
  - Step 3: Goals Selection
    - Primary fitness goal (weight loss, muscle gain, etc.)
    - Specific target areas/objectives
    - Motivation factors
  - Step 4: Workout Preferences
    - Available days per week
    - Time available per session
    - Preferred workout types
    - Indoor/outdoor preference
  - Step 5: Equipment Access
    - Home equipment selection
    - Gym access options
    - No equipment preference
  - Step 6: Dietary Information
    - Dietary restrictions
    - Allergies
    - Eating patterns
    - Food preferences
  - Step 7: Health Considerations
    - Medical conditions
    - Physical limitations
    - Sleep patterns
    - Stress levels
- **Navigation:**
  - "Next" → Subsequent step
  - "Back" → Previous step
  - Final "Complete" → Plan Generation

#### 1.4 Plan Generation Screen
- **UI Components:**
  - Loading animation with percentage
  - AI generation visualization
  - Tips and information cards during wait
- **Features:**
  - Real-time progress updates
  - Educational content display during wait
  - Animated transitions between generation phases
- **Navigation:**
  - Automatic → Dashboard Introduction after completion

#### 1.5 Dashboard Introduction
- **UI Components:**
  - Interactive overlay highlighting key features
  - Step-by-step tutorial cards
  - "Got it" confirmation buttons
- **Features:**
  - Guided tour of main app sections
  - Interactive element demonstrations
  - Quick tips for first-time users
- **Navigation:**
  - "Complete" → Main Dashboard

### 2. Main App Screens

#### 2.1 Home Screen (Dashboard)
- **UI Components:**
  - App bar with profile avatar and settings icon
  - Daily progress circular charts
  - Upcoming workout card
  - Nutrition summary cards
  - Recent metrics visualization
  - Quick action buttons
  - Bottom navigation bar
- **Features:**
  - Today's Plan Section:
    - Next scheduled workout with time/duration
    - Nutrition targets for the day with progress
    - Water intake tracker with quick-add
  - Progress Overview:
    - Weight trend mini-chart (7-day)
    - Workout completion rate
    - Streak calendar (consecutive activity days)
  - AI Insights Card:
    - Personalized tips based on recent activity
    - Motivational messages
  - Quick Actions:
    - Log weight button
    - Log food button
    - Start workout button
    - Chat with AI button
- **Navigation:**
  - Bottom nav bar → Main sections
  - Card taps → Detailed screens
  - Quick action buttons → Relevant logging screens
  - Profile avatar → Profile/Settings

#### 2.2 Workout Screens

##### 2.2.1 Workout Home
- **UI Components:**
  - Weekly calendar with workout indicators
  - Today's workout highlight card
  - Workout plan progress bar
  - Recent workout performance metrics
  - Exercise library quick access
- **Features:**
  - Week Plan View:
    - Visual calendar showing scheduled workouts
    - Color-coded by workout type/intensity
    - Completion indicators
  - Current Plan Overview:
    - Plan name and goal
    - Progress through plan (week x of y)
    - Adjustment recommendations
  - Workout History:
    - Recent workout cards with summary data
    - Performance trends
- **Navigation:**
  - Calendar day → Day's workout details
  - Today's workout → Workout detail view
  - "Start Workout" → Active workout screen
  - "View All History" → Workout history
  - "Exercise Library" → Exercise library screen

##### 2.2.2 Workout Detail View
- **UI Components:**
  - Workout header with type, duration, target
  - Exercise list with thumbnail images
  - Set/rep/weight specifications
  - Rest timer indicators
  - Equipment requirements list
  - "Start Workout" prominent button
- **Features:**
  - Complete workout breakdown
  - Exercise previews (tap to expand)
  - Equipment substitution suggestions
  - Difficulty adjustment controls
  - Exercise reordering option
- **Navigation:**
  - "Start Workout" → Active workout mode
  - Exercise tap → Exercise detail view
  - Back → Workout home
  - Edit → Workout edit mode

##### 2.2.3 Active Workout Screen
- **UI Components:**
  - Current exercise large display
  - Video demonstration
  - Timer/counter
  - Set tracking interface
  - Next exercise preview
  - Workout progress bar
- **Features:**
  - Interactive set completion tracking
  - Rest timer with notifications
  - Weight/rep adjustment controls
  - Voice guidance option
  - Performance tracking
  - Form tips and cues
- **Navigation:**
  - "Next Exercise" → Advances workout
  - "Previous" → Returns to last exercise
  - "Pause" → Pauses workout/timer
  - "End Workout" → Confirmation → Summary

##### 2.2.4 Workout Summary
- **UI Components:**
  - Completion status banner
  - Workout duration and calorie estimate
  - Performance metrics cards
  - Exercise completion list
  - Rating interface
  - Share results button
- **Features:**
  - Performance comparison to previous
  - Achievement badges
  - Notes/feedback input
  - AI-generated performance insights
  - Photo upload option
- **Navigation:**
  - "Done" → Workout home
  - "Share" → Sharing options
  - "Schedule Next" → Calendar view

##### 2.2.5 Exercise Library
- **UI Components:**
  - Search bar with filters
  - Category tabs (muscle groups)
  - Grid/list toggle view
  - Exercise cards with thumbnails
- **Features:**
  - Filtering by:
    - Muscle group
    - Equipment required
    - Difficulty level
    - Exercise type
  - Sorting options
  - Favorites collection
  - Recently viewed section
- **Navigation:**
  - Exercise tap → Exercise detail
  - Back → Workout home
  - Filter icon → Filter panel
  - Search → Search results

##### 2.2.6 Exercise Detail
- **UI Components:**
  - HD video demonstration (looping)
  - Illustrated exercise steps
  - Muscle activation diagram
  - Form guidance notes
  - Alternative exercise suggestions
- **Features:**
  - Playback controls for video
  - Common mistakes warnings
  - Difficulty variations
  - Equipment alternatives
  - Performance tips
- **Navigation:**
  - Back → Exercise library
  - "Add to Workout" → Workout selector
  - "Watch Tutorial" → Full tutorial video

#### 2.3 Nutrition Screens

##### 2.3.1 Nutrition Home
- **UI Components:**
  - Daily macro progress circular charts
  - Meal log timeline
  - Water intake tracker
  - Quick add food buttons
  - Weekly nutrition summary chart
- **Features:**
  - Today's Nutrition:
    - Calorie target vs. consumed
    - Macronutrient breakdown (protein, carbs, fat)
    - Micronutrient highlights
  - Meal Tracking:
    - Visual meal timeline
    - Quick photo logging
    - Meal rating system
  - Food Database Quick Access:
    - Recent foods
    - Favorite foods
    - Custom meals
  - Hydration Tracking:
    - Interactive water tracker
    - Goal visualization
    - Quick-add buttons
- **Navigation:**
  - "Log Food" → Food logging options
  - "Camera" → Photo food recognition
  - Meal tap → Meal detail view
  - "Nutrition Plan" → Full nutrition plan
  - "Analysis" → Nutrition insights

##### 2.3.2 Food Logging
- **UI Components:**
  - Search bar with voice input option
  - Barcode scanner button
  - Recent/frequent foods carousel
  - Meal type selector (breakfast, lunch, etc.)
  - Time picker
- **Features:**
  - Multiple logging methods:
    - Text search
    - Voice search
    - Barcode scanning
    - Image recognition
  - Serving size adjustments
  - Quick add custom items
  - Save as meal template
- **Navigation:**
  - Search results → Food selection
  - "Camera" → Photo recognition
  - "Barcode" → Scanner view
  - "Create Custom" → Custom food form
  - "Save" → Returns to nutrition home

##### 2.3.3 Image Recognition Food Logging
- **UI Components:**
  - Camera viewfinder
  - Photo library access
  - Capture button
  - AI processing indicator
  - Results review interface
- **Features:**
  - Multi-item detection in single photo
  - Portion size estimation
  - Food identification confidence levels
  - Manual adjustment controls
  - Previous recognition history
- **Navigation:**
  - "Confirm" → Nutrition log updated
  - "Retake" → Camera view
  - "Edit" → Manual adjustments
  - "Cancel" → Nutrition home

##### 2.3.4 Nutrition Plan View
- **UI Components:**
  - Weekly meal plan calendar
  - Daily nutrition targets cards
  - Meal suggestion cards
  - Shopping list generation button
  - Plan adjustment controls
- **Features:**
  - Complete nutrition plan overview
  - Daily meal suggestions
  - Alternative meal options
  - Nutritional requirement explanations
  - Adaptation controls based on goals
- **Navigation:**
  - Day tap → Daily meal plan
  - Meal tap → Meal details/recipes
  - "Generate Shopping List" → Shopping list
  - "Adjust Plan" → Plan modification options
  - Back → Nutrition home

##### 2.3.5 Nutrition Insights
- **UI Components:**
  - Trend charts for key nutrients
  - Habit pattern visualizations
  - Recommendation cards
  - Goal alignment indicators
- **Features:**
  - Nutrient intake analysis over time
  - Meal timing pattern recognition
  - Correlation with other metrics (weight, energy)
  - Deficiency/excess warnings
  - AI-generated optimization suggestions
- **Navigation:**
  - Insight card tap → Detailed explanation
  - "Apply Suggestions" → Plan adjustments
  - Back → Nutrition home

#### 2.4 Progress Screens

##### 2.4.1 Progress Home
- **UI Components:**
  - Weight trend chart (with goal line)
  - Measurement tracking cards
  - Photo comparison widget
  - Achievement badges display
  - Logging quick-access buttons
- **Features:**
  - Primary Metrics Tracking:
    - Weight trends with goal visualization
    - Body measurements tracking
    - Body composition estimates
  - Visual Progress:
    - Before/after photo comparisons
    - Timeline view of progress photos
    - Standardized pose guidance
  - Progress Insights:
    - AI analysis of trends
    - Goal progress percentage
    - Projected timeline to goals
  - Achievement System:
    - Milestone badges
    - Streak rewards
    - Challenge completions
- **Navigation:**
  - "Log Weight" → Weight entry
  - "Log Measurements" → Measurements form
  - "Take Progress Photo" → Photo guidance
  - "View All Data" → Detailed metrics
  - "Achievements" → Full achievements page

##### 2.4.2 Weight & Measurement Logging
- **UI Components:**
  - Large numeric input with units
  - Date selector (defaults to today)
  - Previous entry reference
  - Trend mini-chart
  - Notes field
- **Features:**
  - Multiple measurement types
  - Comparison to previous entry
  - Goal alignment indicator
  - Trend visualization
  - Optional context recording
- **Navigation:**
  - "Save" → Progress home with confirmation
  - "History" → Full measurement history
  - Back → Progress home without saving

##### 2.4.3 Progress Photo
- **UI Components:**
  - Camera frame with pose guide overlay
  - Gallery access
  - Previous photo comparison
  - Capture controls
  - Privacy settings
- **Features:**
  - Standardized pose guidance
  - Consistent distance/lighting tips
  - Side-by-side comparison with previous
  - Private storage options
  - Optional AI body composition estimate
- **Navigation:**
  - "Save" → Progress home
  - "Compare" → Photo comparison tool
  - "History" → Photo timeline
  - Back → Progress home

##### 2.4.4 Detailed Metrics
- **UI Components:**
  - Interactive charts with zoom
  - Data table with all entries
  - Multiple metric selection
  - Date range controls
  - Export data button
- **Features:**
  - Comprehensive data visualization
  - Correlation analysis between metrics
  - Custom date range selection
  - Statistical analysis (averages, trends)
  - Data export options
- **Navigation:**
  - Metric selector → Changes displayed data
  - Date range → Adjusts timeline view
  - Data point tap → Detailed entry view
  - Back → Progress home

#### 2.5 AI Assistant Screens

##### 2.5.1 Chat Home
- **UI Components:**
  - Conversation list with previews
  - New chat button
  - Search conversations function
  - Suggested questions chips
  - AI status indicator
- **Features:**
  - Previous conversation history
  - Conversation categorization
  - Quick-start topic suggestions
  - Search through past interactions
  - Favorite/pin important chats
- **Navigation:**
  - Conversation tap → Open chat thread
  - "New Chat" → Fresh conversation
  - Search → Conversation search results
  - Suggested chip → New conversation with prompt
  - Back → Home dashboard

##### 2.5.2 Active Chat
- **UI Components:**
  - Message bubbles (user/AI differentiated)
  - Text input with send button
  - Voice input option
  - Camera/gallery access
  - Suggestion chips based on context
- **Features:**
  - Natural language conversation
  - Multi-modal input (text, voice, images)
  - Context-aware responses
  - In-chat action buttons (e.g., "Add this to my plan")
  - Surfaced relevant user data in responses
- **Navigation:**
  - Send → Submit message
  - Attachment → Media selector
  - Action buttons → Direct to relevant screens
  - Back → Chat home

##### 2.5.3 AI Insights Feed
- **UI Components:**
  - Card-based feed of insights
  - Categorized tabs (workouts, nutrition, general)
  - Interactive elements within cards
  - Dismiss/save controls
- **Features:**
  - Automated insights based on user data
  - Predictive suggestions
  - Habit pattern recognition
  - Goal alignment tips
  - New feature introductions
- **Navigation:**
  - Card tap → Expanded insight
  - "Apply" → Implement suggestion
  - "Learn More" → Detailed explanation
  - "Dismiss" → Remove from feed
  - Back → Home dashboard

#### 2.6 Profile & Settings

##### 2.6.1 Profile Screen
- **UI Components:**
  - Profile header with avatar and key stats
  - Goal visualization
  - Plan subscription details
  - Achievement showcase
  - Edit profile button
- **Features:**
  - User identity management
  - Current goal status
  - Plan details and history
  - Personal records
  - Premium status (if applicable)
- **Navigation:**
  - "Edit Profile" → Profile editing
  - "Settings" → App settings
  - "Goals" → Goal management
  - "Achievements" → Full achievements
  - Back → Home dashboard

##### 2.6.2 Settings Screen
- **UI Components:**
  - Categorized settings list
  - Toggle switches
  - Selection menus
  - Information buttons
  - Version and legal info
- **Features:**
  - App Preferences:
    - Theme selection (dark/light)
    - Notification controls
    - Units selection (metric/imperial)
    - Sound/haptic feedback
  - Account Management:
    - Privacy controls
    - Data export
    - Account deletion
  - AI Settings:
    - Data usage permissions
    - Personalization controls
  - Support & Feedback:
    - Help center access
    - Bug reporting
    - Feature requests
- **Navigation:**
  - Setting tap → Detailed control
  - "About" → App information
  - "Help" → Support resources
  - Back → Profile screen

### 3. Navigation Patterns

#### 3.1 Primary Navigation
- **Bottom Navigation Bar**
  - Always accessible in main app sections
  - 5 core destinations (Home, Workouts, Nutrition, Progress, Chat)
  - Visual indicators for active section
  - Badges for notifications/updates

#### 3.2 Secondary Navigation
- **Side Drawer** (accessible via hamburger menu or edge swipe)
  - Profile shortcut
  - Settings access
  - Additional features:
    - Goals management
    - Achievements
    - Connected devices
    - Help center
  - App information and version

#### 3.3 In-Section Navigation
- **Tab Bars**
  - Used within major sections for sub-sections
  - Horizontally scrollable when needed
  - Underline indicators for current tab

#### 3.4 Contextual Navigation
- **Action Buttons**
  - Floating action buttons for primary actions
  - Context-specific buttons in app bar
  - Inline action buttons within content

#### 3.5 Cross-Section Navigation
- **Deep Links**
  - Generated by AI assistant for direct access
  - Notification deep links to relevant screens
  - Cross-references between related content

#### 3.6 Back Navigation
- **System Back**
  - Returns to previous screen in navigation stack
  - Confirms before exiting editing/creation flows
  - Special handling for multi-step processes

### 4. Design System

#### 4.1 Color Palette
- **Primary Colors**
  - Primary: #6200EE (Deep purple)
  - Primary variant: #3700B3 (Dark purple)
  - Secondary: #03DAC6 (Teal)
  - Secondary variant: #018786 (Dark teal)
- **Supporting Colors**
  - Error: #B00020 (Red)
  - Warning: #FB8C00 (Orange)
  - Success: #43A047 (Green)
  - Info: #2196F3 (Blue)
- **Neutral Colors**
  - Background: #FFFFFF (Light) / #121212 (Dark)
  - Surface: #FFFFFF (Light) / #121212 (Dark)
  - On primary: #FFFFFF
  - On secondary: #000000
  - On background: #000000 (Light) / #FFFFFF (Dark)
  - On surface: #000000 (Light) / #FFFFFF (Dark)

#### 4.2 Typography
- **Font Family**
  - Primary: Roboto
  - Weights: Regular (400), Medium (500), Bold (700)
- **Headings**
  - H1: 96sp
  - H2: 60sp
  - H3: 48sp
  - H4: 34sp
  - H5: 24sp
  - H6: 20sp
- **Body Text**
  - Body 1: 16sp
  - Body 2: 14sp
- **Other**
  - Subtitle 1: 16sp
  - Subtitle 2: 14sp
  - Button: 14sp
  - Caption: 12sp
  - Overline: 10sp

#### 4.3 Component Library
- **Buttons**
  - Contained (high emphasis)
  - Outlined (medium emphasis)
  - Text (low emphasis)
  - Icon buttons
  - Toggle buttons
- **Cards**
  - Elevated cards
  - Outlined cards
  - Filled cards
  - Interactive cards
- **Dialogs & Modals**
  - Alert dialogs
  - Simple dialogs
  - Confirmation dialogs
  - Full-screen dialogs
- **Input Controls**
  - Text fields
  - Checkboxes
  - Radio buttons
  - Switches
  - Sliders
  - Date & time pickers
- **Data Display**
  - Lists
  - Chips
  - Data tables
  - Progress indicators
  - Badges
- **Navigation**
  - Bottom navigation
  - Tabs
  - Drawers
  - Navigation rails
  - App bars

#### 4.4 Animation & Motion
- **Transitions**
  - Screen transitions
  - Shared element transitions
  - Content transitions
- **Feedback**
  - Button ripples
  - Selection ripples
  - Progress indicators
- **Attention**
  - Notifications
  - Alerts
  - Badges

### 5. Responsive Design

#### 5.1 Screen Size Adaptations
- **Phone (Small)**
  - Compact layouts
  - Single column content
  - Bottom navigation
- **Phone (Large) / Small Tablet**
  - Expanded layouts
  - Potential for two-column content
  - Combined navigation patterns
- **Tablet**
  - Multi-column layouts
  - Side-by-side content
  - Navigation rail instead of bottom nav
- **Adaptive Components**
  - Cards that resize based on screen width
  - Collapsible sections on smaller screens
  - Adjustable grid layouts

#### 5.2 Orientation Handling
- **Portrait Mode**
  - Vertically optimized layouts
  - Full-height content scrolling
  - Bottom navigation bar
- **Landscape Mode**
  - Horizontally optimized layouts
  - Side-by-side content panels
  - Navigation rail on side

### 6. Accessibility Features

#### 6.1 Visual Accessibility
- **Text Scaling**
  - All text respects system font size settings
  - Layouts adapt to larger text sizes
- **Color Contrast**
  - All text meets WCAG AA standards for contrast
  - Important elements have distinctive boundaries
- **Dark Mode**
  - Full dark mode support
  - Reduced brightness for nighttime use

#### 6.2 Interactive Accessibility
- **Touch Targets**
  - Minimum 48x48dp touch targets
  - Adequate spacing between interactive elements
- **Screen Reader Support**
  - Semantic markup for all elements
  - Content descriptions for images
  - Announcement of dynamic changes
- **Alternative Navigation**
  - Keyboard navigation support
  - Voice control compatibility

## Backend Architecture (Supabase)

Supabase provides the core backend functionality, including authentication, database, and storage services.

### Authentication System

- Email/password authentication
- Social OAuth (Google, Apple)
- JWT-based session management
- Row-level security policies

### Database Schema

#### User Profile Table

The primary user data table will store all information collected during onboarding:

| Column Name                 | Data Type               | Description                              |
|-----------------------------|-------------------------|------------------------------------------|
| id                          | uuid                    | Primary key                              |
| email                       | text                    | User email                               |
| full_name                   | text                    | User's full name                         |
| created_at                  | timestamp with time zone| Account creation date                    |
| updated_at                  | timestamp with time zone| Last update date                         |
| age                         | integer                 | User's age                               |
| gender                      | text                    | User's gender                            |
| height_cm                   | double precision        | Height in centimeters                    |
| weight_kg                   | double precision        | Weight in kilograms                      |
| fitness_level               | text                    | Beginner/Intermediate/Advanced           |
| weekly_exercise_days        | integer                 | Days per week user exercises             |
| previous_program_experience | boolean                 | Prior fitness program experience         |
| primary_fitness_goal        | text                    | Main goal (weight loss, muscle gain, etc)|
| specific_targets            | text                    | Specific body areas or goals             |
| motivation                  | text                    | User's motivation for fitness            |
| workout_preferences         | jsonb                   | Exercise preferences                     |
| indoor_outdoor_preference   | text                    | Indoor vs outdoor workout preference     |
| workout_days_per_week       | integer                 | Preferred workout frequency              |
| workout_minutes_per_session | integer                 | Preferred workout duration               |
| equipment_access            | text                    | Available equipment                      |
| dietary_restrictions        | jsonb                   | Food restrictions/allergies              |
| eating_habits               | text                    | Meal frequency and patterns              |
| favorite_foods              | text                    | Foods the user enjoys                    |
| avoided_foods               | text                    | Foods the user dislikes                  |
| medical_conditions          | jsonb                   | Health conditions                        |
| medications                 | text                    | Current medications                      |
| fitness_concerns            | text                    | Physical limitations or concerns         |
| daily_activity_level        | text                    | Sedentary/Moderate/Active                |
| sleep_hours                 | integer                 | Average sleep duration                   |
| stress_level                | text                    | Low/Medium/High                          |
| progress_photo_url          | text                    | Reference to profile/progress image      |
| ai_suggestions_enabled      | boolean                 | Opt-in for AI recommendations            |
| additional_notes            | text                    | Any other user information               |
| last_login                  | timestamp with time zone| Latest login timestamp                   |

#### Expanded Database Schema

The following comprehensive schema supports all planned features with appropriate relationships and detailed fields:

```
┌───────────────────────────┐
│        users              │
├───────────────────────────┤
│ id                        │
│ email                     │
│ full_name                 │
│ created_at                │
│ updated_at                │
│ auth_provider             │
│ last_login                │
│ avatar_url                │
│ notification_preferences  │
│ app_settings              │
└───────────────────────────┘
           │
           │
           ▼
┌───────────────────────────┐
│       user_profiles       │
├───────────────────────────┤
│ id                        │
│ user_id                   │
│ age                       │
│ gender                    │
│ height_cm                 │
│ current_weight_kg         │
│ fitness_level             │
│ activity_level            │
│ bmr                       │
│ tdee                      │
│ primary_goal              │
│ specific_targets          │
│ workout_days_per_week     │
│ workout_minutes_per_session│
│ workout_preferences (jsonb)│
│ equipment_access (jsonb)  │
│ dietary_preferences (jsonb)│
│ medical_conditions (jsonb)│
│ medications (jsonb)       │
│ sleep_hours               │
│ stress_level              │
│ experience_level          │
│ updated_at                │
└───────────────────────────┘
           │
           │
           ▼
┌───────────────────────────┐        ┌───────────────────────────┐
│      weight_logs          │        │      body_measurements    │
├───────────────────────────┤        ├───────────────────────────┤
│ id                        │        │ id                        │
│ user_id                   │        │ user_id                   │
│ date                      │        │ date                      │
│ weight_kg                 │        │ measurement_type          │
│ body_fat_percentage       │        │ measurement_value         │
│ mood                      │        │ progress_photo_url        │
│ energy_level              │        │ notes                     │
│ notes                     │        └───────────────────────────┘
└───────────────────────────┘

┌───────────────────────────┐        ┌───────────────────────────┐
│      workout_plans        │        │       workout_weeks       │
├───────────────────────────┤        ├───────────────────────────┤
│ id                        │        │ id                        │
│ user_id                   │        │ plan_id                   │
│ name                      │        │ week_number               │
│ description               │        │ start_date                │
│ goal                      │        │ end_date                  │
│ level                     │        │ notes                     │
│ duration_weeks            │        └───────────────────────────┘
│ creator_type              │              │
│ created_at                │              │
│ last_updated              │              ▼
│ is_active                 │        ┌───────────────────────────┐
│ metadata (jsonb)          │        │      workout_sessions     │
└───────────────────────────┘        ├───────────────────────────┤
                                     │ id                        │
                                     │ week_id                   │
                                     │ day_of_week               │
                                     │ name                      │
                                     │ focus                     │
                                     │ duration_minutes          │
                                     │ intensity                 │
                                     │ calories_burned_estimate  │
                                     │ notes                     │
                                     └───────────────────────────┘
                                              │
                                              │
                                              ▼
┌───────────────────────────┐        ┌───────────────────────────┐
│   workout_exercises       │        │    completed_workouts     │
├───────────────────────────┤        ├───────────────────────────┤
│ id                        │        │ id                        │
│ session_id                │        │ user_id                   │
│ exercise_id               │        │ session_id                │
│ order_index               │        │ completed_date            │
│ sets                      │        │ duration_minutes          │
│ reps_per_set              │        │ perceived_difficulty      │
│ weight_kg                 │        │ calories_burned           │
│ rest_seconds              │        │ notes                     │
│ is_warmup                 │        │ rating                    │
│ is_dropset                │        │ image_url                 │
│ notes                     │        └───────────────────────────┘
└───────────────────────────┘                │
          │                                  │
          │                                  ▼
          ▼                         ┌───────────────────────────┐
┌───────────────────────────┐       │   completed_exercises     │
│     exercise_library      │       ├───────────────────────────┤
├───────────────────────────┤       │ id                        │
│ id                        │       │ completed_workout_id      │
│ name                      │       │ exercise_id               │
│ description               │       │ sets_completed            │
│ instructions              │       │ reps_completed            │
│ demonstration_url         │       │ weight_used_kg            │
│ difficulty                │       │ notes                     │
│ equipment_needed (jsonb)  │       └───────────────────────────┘
│ muscle_groups (jsonb)     │
│ secondary_muscles (jsonb) │
│ exercise_type             │
│ movement_pattern          │
│ is_compound               │
│ calories_per_rep_estimate │
│ safety_tips               │
└───────────────────────────┘

┌───────────────────────────┐        ┌───────────────────────────┐
│      nutrition_plans      │        │      daily_nutrition      │
├───────────────────────────┤        ├───────────────────────────┤
│ id                        │        │ id                        │
│ user_id                   │        │ plan_id                   │
│ name                      │        │ day_of_week               │
│ description               │        │ calorie_target            │
│ daily_calories            │        │ protein_target_g          │
│ protein_target_g          │        │ carbs_target_g            │
│ carbs_target_g            │        │ fat_target_g              │
│ fat_target_g              │        │ fiber_target_g            │
│ created_at                │        │ water_target_ml           │
│ last_updated              │        │ meal_count                │
│ is_active                 │        │ notes                     │
│ metadata (jsonb)          │        └───────────────────────────┘
└───────────────────────────┘                 │
                                              │
                                              ▼
┌───────────────────────────┐        ┌───────────────────────────┐
│         food_logs         │        │       meal_templates      │
├───────────────────────────┤        ├───────────────────────────┤
│ id                        │        │ id                        │
│ user_id                   │        │ plan_id                   │
│ date                      │        │ name                      │
│ meal_type                 │        │ meal_type                 │
│ meal_time                 │        │ description               │
│ hunger_level              │        │ calorie_range             │
│ satiety_level             │        │ protein_g                 │
│ mood                      │        │ carbs_g                   │
│ location                  │        │ fat_g                     │
│ image_url                 │        │ preparation_time_minutes  │
│ notes                     │        │ suggested_timing          │
└───────────────────────────┘        │ recipe_instructions       │
          │                          └───────────────────────────┘
          │
          ▼
┌───────────────────────────┐        ┌───────────────────────────┐
│      food_log_items       │        │        food_items         │
├───────────────────────────┤        ├───────────────────────────┤
│ id                        │        │ id                        │
│ log_id                    │        │ name                      │
│ food_item_id              │        │ description               │
│ serving_size              │        │ brand                     │
│ quantity                  │        │ category                  │
│ calories                  │        │ food_group                │
│ protein_g                 │        │ serving_size              │
│ carbs_g                   │        │ serving_unit              │
│ fat_g                     │        │ calories                  │
│ fiber_g                   │        │ protein_g                 │
│ sugar_g                   │        │ carbs_g                   │
│ sodium_mg                 │        │ fat_g                     │
│ ai_identified             │        │ saturated_fat_g           │
└───────────────────────────┘        │ trans_fat_g               │
                                     │ cholesterol_mg            │
                                     │ sodium_mg                 │
                                     │ fiber_g                   │
                                     │ sugar_g                   │
                                     │ vitamins (jsonb)          │
                                     │ minerals (jsonb)          │
                                     │ ingredients               │
                                     │ image_url                 │
                                     │ barcode                   │
                                     │ is_verified               │
                                     └───────────────────────────┘

┌───────────────────────────┐        ┌───────────────────────────┐
│       water_logs          │        │        sleep_logs         │
├───────────────────────────┤        ├───────────────────────────┤
│ id                        │        │ id                        │
│ user_id                   │        │ user_id                   │
│ date                      │        │ date                      │
│ amount_ml                 │        │ bedtime                   │
│ timestamp                 │        │ wake_time                 │
└───────────────────────────┘        │ duration_minutes          │
                                     │ quality_rating            │
                                     │ disruptions               │
                                     │ notes                     │
                                     └───────────────────────────┘

┌───────────────────────────┐        ┌───────────────────────────┐
│      ai_chat_sessions     │        │      ai_chat_messages     │
├───────────────────────────┤        ├───────────────────────────┤
│ id                        │        │ id                        │
│ user_id                   │        │ session_id                │
│ title                     │        │ timestamp                 │
│ created_at                │        │ is_user                   │
│ last_message_at           │        │ message_content           │
│ session_type              │        │ message_type              │
│ is_archived               │        │ context_data (jsonb)      │
└───────────────────────────┘        │ image_url                 │
          │                          │ processed_by              │
          │                          └───────────────────────────┘
          ▼
┌───────────────────────────┐
│      ai_suggestions       │
├───────────────────────────┤
│ id                        │
│ user_id                   │
│ created_at                │
│ suggestion_type           │
│ suggestion_content        │
│ context_trigger           │
│ is_read                   │
│ is_implemented            │
│ feedback                  │
└───────────────────────────┘
```

### Storage Structure

Organized storage buckets for various assets:

- **profile_images/**: User profile pictures
- **food_images/**: Food logging photographs
- **progress_photos/**: Body progress tracking images
- **exercise_media/**: Instructional videos and images

### Realtime Subscriptions

- Instant UI updates when data changes
- Notifications for plan adjustments
- Live chat with AI assistant

## AI Architecture (Hybrid Approach)

FitAI implements a hybrid AI architecture that leverages both Flutter Gemini for direct, device-integrated AI capabilities and n8n for specialized AI workflows.

### AI Responsibility Distribution

```
┌─────────────────────────────────────────────────────────────┐
│ Flutter Gemini (In-App AI)                                  │
├─────────────────────────────────────────────────────────────┤
│ ● Food Image Recognition                                    │
│ ● Conversational AI Chat Assistant                          │
│ ● Visual Content Analysis                                   │
│ ● User Query Processing                                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ n8n Workflows (Server-based AI)                             │
├─────────────────────────────────────────────────────────────┤
│ ● Workout Plan Generation                                   │
│ ● Nutrition Plan Creation                                   │
│ ● Plan Adjustment Based on Progress                         │
│ ● Complex Data Analysis and Insights                        │
└─────────────────────────────────────────────────────────────┘
```

### Key AI Workflows

#### 1. Onboarding & Profile Setup

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ User        │     │ Flutter App │     │ Supabase    │     │ n8n         │
│ completes   │────►│ sends      │────►│ stores      │────►│ processes   │
│ onboarding  │     │ profile data│     │ user data   │     │ user data   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                   │
┌─────────────┐     ┌─────────────┐     ┌─────────────┐           │
│ Supabase    │     │ Flutter App │     │ User views  │           │
│ stores      │◄────│ receives    │◄────│ generated   │◄──────────┘
│ AI plans    │     │ AI plans    │     │ plans       │
└─────────────┘     └─────────────┘     └─────────────┘
```

This workflow:
1. Processes user onboarding data from Supabase
2. Uses n8n to connect to OpenAI to generate personalized nutrition and workout plans
3. Stores generated plans back in Supabase

#### 2. Food Image Recognition (Gemini)

```
┌─────────────┐     ┌─────────────────────┐     ┌─────────────┐
│ User takes  │     │ Flutter App with    │     │ Gemini      │
│ food photo  │────►│ Gemini integration  │────►│ processes   │
│             │     │                     │     │ image       │
└─────────────┘     └─────────────────────┘     └─────────────┘
                                                      │
                                                      ▼
┌─────────────┐     ┌─────────────┐           ┌─────────────┐
│ User        │     │ Flutter App │           │ Supabase    │
│ confirms    │◄────│ displays    │◄──────────│ stores      │
│ results     │     │ results     │           │ nutrition   │
└─────────────┘     └─────────────┘           └─────────────┘
```

This workflow:
1. Processes food images directly in the Flutter app using Gemini Pro Vision
2. Identifies food items and estimates portions
3. Retrieves or calculates nutritional data
4. Allows user to confirm the identification
5. Stores the logged meal in Supabase

#### 3. Workout & Nutrition Plan Generation (n8n)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ User        │     │ Flutter App │     │ n8n         │
│ requests    │────►│ sends       │────►│ triggers    │
│ plans       │     │ request     │     │ generation  │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ User views  │     │ Flutter App │     │ Supabase    │
│ new plans   │◄────│ displays    │◄────│ stores      │
│             │     │ plans       │     │ plans       │
└─────────────┘     └─────────────┘     └─────────────┘
```

This workflow:
1. Uses n8n to create personalized workout and nutrition plans
2. Connects to OpenAI for sophisticated plan generation
3. For workout plans, includes specific exercises from the exercise library
4. For nutrition plans, focuses on macro and micronutrient targets
5. Adjusts plans based on progress data (like weight changes)

#### 4. AI Chat Assistant (Gemini)

```
┌─────────────┐     ┌─────────────────────┐     ┌─────────────┐
│ User sends  │     │ Flutter App with    │     │ Gemini      │
│ message     │────►│ Gemini integration  │────►│ processes   │
│             │     │                     │     │ message     │
└─────────────┘     └─────────────────────┘     └─────────────┘
                           ▲   │
                           │   ▼
┌─────────────┐     ┌─────────────┐
│ User reads  │     │ Supabase    │
│ response    │◄────│ (context    │
│             │     │  data)      │
└─────────────┘     └─────────────┘
```

This workflow:
1. Processes user messages directly in the app using Gemini
2. Fetches relevant context data from Supabase as needed
3. Generates personalized responses with Gemini's conversational capabilities
4. Displays the response to the user
5. Optionally logs conversation data to Supabase

### AI Service Integrations

#### Gemini Integration

- **Purpose**: Powers the food image recognition and AI chat assistant
- **Implementation**: Direct integration in Flutter app via `google_generative_ai` package
- **Key Features**:
  - Multi-modal capabilities (text, images)
  - On-device processing capabilities
  - Context-aware conversations
  - Visual content analysis

#### OpenAI GPT Integration (via n8n)

- **Purpose**: Powers specialized workout and nutrition plan generation
- **Implementation**: OpenAI API integration within n8n workflows
- **Key Features**:
  - Sophisticated plan creation
  - Structured output generation
  - Adaptation based on user data

## Integration Architecture

The overall integration between components in our hybrid approach:

```
┌─────────────────────────────────────────────────────────────┐
│ Flutter Mobile App                                          │
│ ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│ │  UI Layer   │    │Local Storage│    │ API Service │      │
│ └─────────────┘    └─────────────┘    └─────────────┘      │
│           │                 │                │              │
│           ▼                 │                ▼              │
│ ┌────────────────┐          │         ┌────────────────┐   │
│ │ Gemini Service │          │         │ Remote Service │   │
│ └────────────────┘          │         └────────────────┘   │
└──────────┬────────────────────────────────────┬────────────┘
           │                  │                 │
           │                  ▼                 │
           │   ┌─────────────────────────────┐  │
           │   │ Supabase                    │  │
           │   │ ┌─────────┐  ┌─────────┐    │  │
           │   │ │  Auth   │  │Database │    │  │
           │   │ └─────────┘  └─────────┘    │  │
           │   │        ┌─────────┐          │  │
           │   │        │ Storage │          │  │
           │   │        └─────────┘          │  │
           │   └───────────────┬─────────────┘  │
           │                   │                │
           ▼                   │                ▼
┌─────────────────┐            │       ┌───────────────────┐
│                 │            │       │                   │
│   Gemini API    │            │       │  n8n Workflows    │
│   (Google)      │            │       │  (Plan Generation)│
│                 │            │       │                   │
└─────────────────┘            │       └─────────┬─────────┘
                               │                 │
                               │                 ▼
                               │       ┌───────────────────┐
                               │       │                   │
                               └──────►│     OpenAI API    │
                                       │                   │
                                       └───────────────────┘
```

### API Design

- RESTful API endpoints for standard operations
- Realtime channels for live updates
- Webhook endpoints for n8n workflow triggers

### Security Implementation

- JWT authentication for API access
- Row-level security in Supabase
- End-to-end encryption for sensitive data
- Secure API key management for external services

## User Flows

### 1. Onboarding Flow

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│            │     │            │     │            │     │            │
│  Welcome   │────►│  Account   │────►│  Profile   │────►│  Goals &   │
│  Screen    │     │  Creation  │     │  Setup     │     │ Preferences│
│            │     │            │     │            │     │            │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
                                                                │
                                                                ▼
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│            │     │            │     │            │     │            │
│  Dashboard │◄────│   Plan     │◄────│  Dietary   │◄────│  Fitness   │
│  Intro     │     │ Generation │     │ Questions  │     │ Assessment │
│            │     │            │     │            │     │            │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
```

1. User creates account (email/password or social login)
2. Completes detailed profile questionnaire
3. Sets goals and preferences
4. Completes fitness assessment
5. Answers dietary questions
6. AI generates initial plans
7. User is introduced to the dashboard

### 2. Food Logging Flow with Gemini

```
┌────────────┐     ┌────────────┐     ┌─────────────────┐     ┌────────────┐
│            │     │            │     │                 │     │            │
│ Nutrition  │────►│  Camera    │────►│ Flutter Gemini  │────►│ Review &   │
│ Dashboard  │     │  Capture   │     │ Processing      │     │ Confirm    │
│            │     │            │     │                 │     │            │
└────────────┘     └────────────┘     └─────────────────┘     └────────────┘
                                                                     │
                                                                     ▼
                                                              ┌────────────┐
                                                              │            │
                                                              │ Updated    │
                                                              │ Nutrition  │
                                                              │ Dashboard  │
                                                              │            │
                                                              └────────────┘
```

1. User navigates to Nutrition section
2. Takes photo of food
3. Gemini AI directly processes the image in the app and identifies food
4. User reviews and confirms identification
5. Nutritional data is added to daily log
6. Dashboard updates with new nutritional totals

### 3. Workout Plan Flow

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│            │     │            │     │            │
│ Workout    │────►│  Weekly    │────►│ Exercise   │
│ Dashboard  │     │  Schedule  │     │ Details    │
│            │     │            │     │            │
└────────────┘     └────────────┘     └────────────┘
      ▲                                      │
      │                                      │
      │            ┌────────────┐            │
      │            │            │            │
      └────────────┤ Mark as    │◄───────────┘
                   │ Done       │
                   │            │
                   └────────────┘
```

1. User views weekly workout schedule
2. Selects a workout for the day
3. Views detailed exercise instructions
4. Performs the workout
5. Marks workout as completed

### 4. Progress Tracking Flow

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│            │     │            │     │            │
│ Progress   │────►│  Enter     │────►│ Updated    │
│ Dashboard  │     │  Weight    │     │ Metrics    │
│            │     │            │     │            │
└────────────┘     └────────────┘     └────────────┘
                                             │
                                             ▼
                                      ┌────────────┐
                                      │            │
                                      │ AI Insights│
                                      │ & Trends   │
                                      │            │
                                      └────────────┘
```

1. User accesses progress tracking screen
2. Enters new weight measurement
3. Views updated progress charts
4. Receives AI-generated insights
5. If significant changes detected, informed that they might need to regenerate plans (plans are not automatically regenerated with every weight change)

### 5. AI Chat Assistant Flow with Gemini

```
┌────────────┐     ┌────────────┐     ┌────────────────────┐
│            │     │            │     │                    │
│ Chat       │────►│ Send       │────►│ Gemini AI          │
│ Dashboard  │     │ Message    │     │ In-App Processing  │
│            │     │            │     │                    │
└────────────┘     └────────────┘     └────────────────────┘
      ▲                                     │      ▲
      │                                     │      │
      │                                     ▼      │
      │            ┌────────────┐    ┌────────────┐
      │            │            │    │            │
      └────────────┤ Receive    │◄───┤ Context    │
                   │ Response   │    │ from DB    │
                   │            │    │            │
                   └────────────┘    └────────────┘
```

1. User opens chat interface
2. Types question or request
3. Gemini AI processes the message directly in the app
4. Retrieves relevant context from Supabase if needed
5. Returns personalized response with context awareness
6. Can handle follow-up questions or requests with conversation history

## Development Strategy

### Phase 1: Foundation
- Set up project structure
- Configure Supabase and database schema
- Create basic Flutter app architecture
- Implement authentication
- Set up n8n environment

### Phase 2: Core Functionality
- Build onboarding flow
- Implement user profile management
- Create basic dashboard UI
- Develop workout and nutrition plan structures
- Set up basic progress tracking

### Phase 3: AI Integration
- Set up n8n workflows for workout and nutrition plan generation with OpenAI
- Integrate Flutter Gemini for food image recognition
- Implement Gemini-powered chat assistant
- Create hybrid AI orchestration layer for seamless user experience
- Develop AI-driven insights and analytics using both systems
- Implement fallback mechanisms between AI systems for reliability

### Phase 4: Refinement
- UI/UX polish and Material 3 implementation
- Performance optimization
- Comprehensive testing
- Beta testing and feedback collection
- Final adjustments and bug fixes

## Future Expansion

Potential future enhancements leveraging our hybrid AI architecture:

### Gemini-powered enhancements
- **On-device Workout Analysis**: Using Gemini for real-time form analysis during exercises
- **Voice Interaction**: Natural voice commands and Gemini-powered verbal responses
- **Multimodal Understanding**: Analyzing progress photos with textual context for deeper insights
- **Real-time Food Recognition**: Instant food identification during meals without server roundtrips
- **Offline AI Capabilities**: Enhanced functionality when internet connection is limited

### n8n workflow enhancements
- **Advanced Plan Optimization**: More sophisticated workout and nutrition planning
- **Integration with Health Data Platforms**: Connect with Apple Health, Google Fit
- **Wearable Device Support**: Data integration with fitness trackers and smartwatches

### General platform enhancements
- **Social Features**: Friend connections, challenges, sharing capabilities
- **Advanced Visualization**: 3D body models and detailed progress visualization
- **Personalized Meal Planning**: AI-generated meal suggestions based on preferences
- **Community Features**: User forums and group challenges

---

This architecture document provides a comprehensive blueprint for developing the FitAI application. It addresses all requirements while maintaining flexibility for future enhancements.