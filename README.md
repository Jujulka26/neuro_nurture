NeuroNurture
NeuroNurture is an engaging educational mobile application designed to make learning fun for children while providing parents with tools to monitor their child's progress. Built with Flutter, it offers interactive games focused on shapes, colors, and numbers, all within a secure, parent-controlled environment.

✨ Features
User Authentication: Secure login and sign-up functionality using Firebase Authentication for personalized experiences.
Parental PIN Access: A dedicated 4-digit PIN system protects sensitive areas like the Dashboard, ensuring parents can safely monitor progress. Parents can set this PIN during their initial sign-up or login.
Interactive Educational Games:
Group the Shape: A drag-and-drop game where children match shapes to their corresponding outlines.
Matching Colour: An intuitive game designed to help children identify and match colors.
Sort Number: A game focused on teaching number recognition and ordering.
Game Progress Tracking: Scores from completed games are securely saved to Google Cloud Firestore, allowing parents to track their child's learning journey.
Immersive Audio Experience:
Dynamic Background Music: Custom background music with smooth fade-in/out transitions enhances the overall atmosphere.
Responsive Sound Effects: Engaging sound effects for clicks, correct answers, wrong attempts, and game-over scenarios provide immediate feedback.
Smooth User Experience: Enjoy seamless page transitions with custom animations and a dedicated loading screen featuring beautiful Lottie animations.
Persistent Login: Users stay logged in across app sessions, providing a convenient and continuous learning experience.
Landscape Optimization: The application is specifically designed and optimized for a landscape orientation, offering a consistent and engaging layout.
🚀 Technologies Used
Flutter: The UI toolkit used for building natively compiled applications for mobile, web, and desktop from a single codebase.
Firebase: Utilized for:
Authentication: Managing user sign-up and login.
Firestore: A NoSQL cloud database for storing game scores and user-specific data like parental PINs.
shared_preferences: For lightweight data storage, primarily used for maintaining login status.
lottie: Integrates beautiful, scalable Lottie animations for loading screens and enhancing UI.
audioplayers: (Managed by SoundController and MusicController) For playing background music and sound effects.
🛠️ Installation & Setup
To get NeuroNurture up and running on your local machine, follow these steps:

Clone the repository:
Bash

git clone <repository_url>
cd NeuroNurture
Install Flutter dependencies:
Bash

flutter pub get
Firebase Project Setup:
Create a new Firebase project in the Firebase Console.
Add an Android app to your Firebase project. Follow the setup instructions to download google-services.json and place it in android/app/.
(Optional, if targeting iOS) Add an iOS app to your Firebase project. Follow the setup instructions to download GoogleService-Info.plist and place it in ios/Runner/.
Enable Email/Password authentication in your Firebase project (Authentication > Sign-in method).
Enable Firestore Database in your Firebase project (Firestore Database > Create database).
Run the application:
Bash

flutter run
Ensure your device or emulator is set to landscape orientation.
🎮 How to Play
Sign Up / Log In: Create a new account or log in with existing credentials. If it's your first time logging in, you'll be prompted to set a 4-digit parental PIN.
Main Menu: From the StartPage, tap the "Play" button to proceed to the main menu.
Select a Game: Choose from "Group the Shape", "Matching Colour", or "Sort Number" to start playing.
Dashboard: Access the "Dashboard" via the main menu to view game statistics. You'll need to enter your parental PIN to proceed.
Settings: Tap the settings icon in the main menu to adjust audio settings or log out.

Credits (Background Music)

Music track: Healing Spell by Piki
Source: https://freetouse.com/music
No Copyright Music (Free Download)

Music track: Kitty by Piki
Source: https://freetouse.com/music
Free Vlog Music Without Copyright

Music track: Happy Walking by Piki
Source: https://freetouse.com/music
No Copyright Vlog Music for Videos
