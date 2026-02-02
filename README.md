# Smart Expense Tracker

A powerful, intelligent Flutter application for managing personal finances. Smart Expense Tracker automates expense logging through SMS sync, voice input, and receipt scanning, providing deep insights into your spending habits.

## 🌟 Key Features

*   **🤖 Smart SMS Sync**: Automatically reads transaction SMS from banks to log expenses without manual entry.
*   **🗣️ Voice Input**: robust voice recognition to add expenses simply by speaking (e.g., "Spent 500 on groceries").
*   **📸 Receipt Scanning**: Uses Google ML Kit to scan receipt images and automatically extract vendor and amount.
*   **📊 Visual Analytics**:
    *   **Daily & Monthly Breakdowns**: Interactive bar and line charts.
    *   **Category Analysis**: Pie charts to visualize spending distribution.
    *   **Spending Insights**: Auto-calculated daily averages and top spending days.
*   **💰 Budget Management**: Set monthly limits for specific categories and get visual progress indicators.
*   **🌓 Adaptive UI**: Beautiful, modern UI that adapts to system Light/Dark mode preferences.

## 🛠️ Tech Stack

*   **Framework**: Flutter
*   **State Management**: BLoC (Business Logic Component)
*   **Database**: Sqflite (Local Offline Storage)
*   **Charts**: FL Chart
*   **ML & Input**:
    *   `google_ml_kit_text_recognition` (OCR)
    *   `speech_to_text` (Voice)
    *   `flutter_telephony` (SMS Reading)

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (3.0+)
*   Android Studio / VS Code
*   Android Device/Emulator (SMS and Camera features require a real device or configured emulator)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/Parth369000/smart_expense_tracker.git
    cd smart_expense_tracker
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

## 📱 Permissions

The app requires the following permissions for full functionality:
*   **SMS**: To read transaction messages for auto-sync.
*   **Camera**: To scan receipts.
*   **Microphone**: For voice input.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
