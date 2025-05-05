# DUBE

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

A modern Flutter application for efficient business management, featuring robust authentication, multi-language support, and comprehensive transaction handling. Built with Supabase backend integration, DUBE provides a secure and user-friendly experience for managing customers, products, and financial transactions.

## 📑 Table of Contents
- [Features](#-features)
- [Technical Stack](#️-technical-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#️-project-structure)
- [Internationalization](#-internationalization)
- [Core Features](#-core-features)
- [Technical Specifications](#-technical-specifications)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)
- [Acknowledgments](#-acknowledgments)

## 🌟 Features

- **Business Management**
  - Customer management
  - Product inventory
  - Transaction tracking
  - Financial reconciliation
  - Summary reports

- **Multi-language Support**
  - English interface
  - Amharic interface (አማርኛ)
  - Dynamic language switching

- **Modern UI/UX**
  - Clean interface
  - Responsive design
  - Dark/Light theme
  - Loading states
  - Error handling

- **Security & Validation**
  - Secure authentication
  - Data validation
  - Error handling
  - Offline data support

## 🛠️ Technical Stack

- **Frontend**: Flutter (Latest SDK)
- **Backend**: Supabase
- **Database**: PostgreSQL
- **State Management**: Provider
- **Localization**: Flutter Intl
- **Storage**: Supabase Storage
- **Authentication**: Supabase Auth

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Supabase account
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/dube.git
   cd dube
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a new Supabase project
   - Copy your Supabase URL and anon key
   - Create a `.env` file:
     ```env
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── l10n/
│   ├── app_am.arb    # Amharic translations
│   └── app_en.arb    # English translations
├── models/
│   ├── customer.dart
│   ├── product.dart
│   ├── profile.dart
│   └── transaction.dart
├── providers/
│   ├── language_provider.dart
│   ├── locale_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── auth/
│   │   └── auth_screen.dart
│   ├── customers/
│   │   └── [customer management screens]
│   ├── home/
│   │   └── [dashboard screens]
│   ├── products/
│   │   └── [inventory screens]
│   ├── profile/
│   │   └── [user profile screens]
│   ├── reconciliation/
│   │   └── [financial reconciliation screens]
│   └── summary/
│       └── [report screens]
├── services/
│   └── [service files]
├── theme/
│   └── [theme configuration]
└── main.dart
```

## 🌍 Internationalization

### Supported Languages
- 🇺🇸 English
- 🇪🇹 Amharic (አማርኛ)

### Language Management
```dart
class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  
  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }
}
```

## 💼 Core Features

### 1. Customer Management
- Customer registration and profiles
- Transaction history
- Contact information
- Account status tracking

### 2. Product Management
- Inventory tracking
- Price management
- Stock alerts
- Product categories

### 3. Transaction Processing
- Sales recording
- Payment processing
- Receipt generation
- Transaction history

### 4. Financial Reconciliation
- Balance verification
- Transaction matching
- Discrepancy resolution
- Audit trails

### 5. Business Analytics
- Sales reports
- Customer insights
- Product performance
- Financial summaries

## 🔍 Technical Specifications

### State Management
```dart
// Theme management
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
```

### Data Models
```dart
// Example Product Model
class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String category;
  
  // Model implementation
}
```

### Error Handling
```dart
class AppErrorHandler {
  static void handleError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Biruk G. Jember**
- GitHub: [@Biruk-gebru](https://github.com/Biruk-gebru)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase team for the backend infrastructure
- Provider package maintainers
- Flutter Intl package for localization support

---
<div align="center">
Made by Biruk G. Jember
</div>
