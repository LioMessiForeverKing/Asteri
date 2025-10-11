# 📄 Asteria Theme Guide

Welcome to the Asteria theme system! This guide shows you how to use the paper-inspired, animated cartoon aesthetic throughout your app.

## 🎨 Quick Start

The theme is already applied in `main.dart`. All your widgets will automatically use the themed styles!

```dart
MaterialApp(
  theme: AsteriaTheme.lightTheme,
  home: YourHomePage(),
)
```

## 🎯 Using Theme Colors

### Primary Colors (Coral/Terracotta)
```dart
Container(color: AsteriaTheme.primaryColor)
Container(color: Theme.of(context).colorScheme.primary)
```

### Secondary Colors (Soft Purple)
```dart
Container(color: AsteriaTheme.secondaryColor)
```

### Accent Colors (Playful Yellow/Gold)
```dart
Container(color: AsteriaTheme.accentColor)
```

### Background Colors (Warm Paper Tones)
```dart
Container(color: AsteriaTheme.backgroundPrimary)     // Main background
Container(color: AsteriaTheme.backgroundSecondary)   // Cards, surfaces
Container(color: AsteriaTheme.backgroundTertiary)    // Subtle variations
```

### Text Colors
```dart
Text('Primary', style: TextStyle(color: AsteriaTheme.textPrimary))
Text('Secondary', style: TextStyle(color: AsteriaTheme.textSecondary))
Text('Tertiary', style: TextStyle(color: AsteriaTheme.textTertiary))
```

## ✍️ Typography

### Headings (Quicksand - Playful & Rounded)
```dart
Text('Display', style: Theme.of(context).textTheme.displayLarge)
Text('Headline', style: Theme.of(context).textTheme.headlineMedium)
Text('Title', style: Theme.of(context).textTheme.titleLarge)
```

### Body Text (Figtree - Clean & Readable)
```dart
Text('Body text here', style: Theme.of(context).textTheme.bodyLarge)
Text('Smaller text', style: Theme.of(context).textTheme.bodyMedium)
```

### Labels (Quicksand - For Buttons & Tags)
```dart
Text('Label', style: Theme.of(context).textTheme.labelLarge)
```

## 🎪 Paper-like Cards

### Standard Card (Automatic Theme)
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(AsteriaTheme.spacingMedium),
    child: Text('Content'),
  ),
)
```

### Custom Paper Card Decoration
```dart
Container(
  decoration: AsteriaTheme.paperCardDecoration(),
  padding: EdgeInsets.all(AsteriaTheme.spacingMedium),
  child: Text('Custom paper card'),
)
```

### Elevated Paper (Higher Shadow)
```dart
Container(
  decoration: AsteriaTheme.elevatedPaperDecoration(),
  child: Text('Modal or important content'),
)
```

### Inset Paper (Pressed State)
```dart
Container(
  decoration: AsteriaTheme.insetPaperDecoration(),
  child: Text('Pressed or selected state'),
)
```

### Gradient Overlay
```dart
Container(
  decoration: AsteriaTheme.gradientOverlayDecoration(),
  child: Text('Special section'),
)
```

## 🔘 Buttons

All buttons are automatically themed!

```dart
// Primary action - Coral with warm shadow
ElevatedButton(
  onPressed: () {},
  child: Text('Primary Action'),
)

// Secondary action - Outlined
OutlinedButton(
  onPressed: () {},
  child: Text('Secondary'),
)

// Tertiary action - Text only
TextButton(
  onPressed: () {},
  child: Text('Tertiary'),
)

// Floating action - Yellow/Gold accent
FloatingActionButton(
  onPressed: () {},
  child: Icon(Icons.add),
)
```

## 📐 Spacing & Sizing

### Spacing Constants
```dart
SizedBox(height: AsteriaTheme.spacingXSmall)    // 4px
SizedBox(height: AsteriaTheme.spacingSmall)     // 8px
SizedBox(height: AsteriaTheme.spacingMedium)    // 16px
SizedBox(height: AsteriaTheme.spacingLarge)     // 24px
SizedBox(height: AsteriaTheme.spacingXLarge)    // 32px
SizedBox(height: AsteriaTheme.spacingXXLarge)   // 48px
```

### Border Radius
```dart
BorderRadius.circular(AsteriaTheme.radiusSmall)    // 12px
BorderRadius.circular(AsteriaTheme.radiusMedium)   // 16px
BorderRadius.circular(AsteriaTheme.radiusLarge)    // 24px
BorderRadius.circular(AsteriaTheme.radiusXLarge)   // 32px
```

### Elevation
```dart
elevation: AsteriaTheme.elevationLow      // 2dp
elevation: AsteriaTheme.elevationMedium   // 4dp
elevation: AsteriaTheme.elevationHigh     // 8dp
elevation: AsteriaTheme.elevationXHigh    // 12dp
```

## 📝 Input Fields

Input fields are automatically themed with paper-like styling:

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email',
    prefixIcon: Icon(Icons.email),
  ),
)
```

## 🏷️ Chips & Tags

```dart
Chip(
  label: Text('Tag'),
  avatar: Icon(Icons.tag, size: 16),
)

Chip(
  label: Text('Deletable'),
  onDeleted: () {},
)
```

## 🔔 Dialogs & Snackbars

### Show Dialog
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Title'),
    content: Text('Content'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Confirm'),
      ),
    ],
  ),
)
```

### Show Snackbar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message')),
)
```

### Bottom Sheet
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    padding: EdgeInsets.all(AsteriaTheme.spacingLarge),
    child: Text('Bottom sheet content'),
  ),
)
```

## 🎨 Status Colors

For success, warning, error, and info states:

```dart
Container(color: AsteriaTheme.successColor)  // Green
Container(color: AsteriaTheme.warningColor)  // Orange
Container(color: AsteriaTheme.errorColor)    // Red
Container(color: AsteriaTheme.infoColor)     // Blue
```

## 🖼️ Using the Asteria Logo

The logo is already in your assets:

```dart
// SVG Logo
Image.asset('assets/Logos/Asteri.svg')

// PNG Logo
Image.asset('assets/Logos/Asteri.png')
```

## 💡 Pro Tips

### 1. Layered Paper Effect
Stack multiple containers with different elevations for a 3D paper stack effect:

```dart
Stack(
  children: [
    Positioned(
      top: 8,
      left: 8,
      child: Container(
        decoration: AsteriaTheme.paperCardDecoration(
          elevation: AsteriaTheme.elevationLow,
        ),
      ),
    ),
    Container(
      decoration: AsteriaTheme.paperCardDecoration(
        elevation: AsteriaTheme.elevationMedium,
      ),
    ),
  ],
)
```

### 2. Animated Paper Flutter
Add subtle animations to cards for that animated cartoon feel:

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeOutBack,
  decoration: isHovered 
    ? AsteriaTheme.elevatedPaperDecoration()
    : AsteriaTheme.paperCardDecoration(),
  child: child,
)
```

### 3. Warm Shadows
The shadows are already warm-toned to match the paper aesthetic. They use the primary color with low opacity instead of black.

### 4. Custom Decorations
Mix and match properties:

```dart
Container(
  decoration: AsteriaTheme.paperCardDecoration(
    backgroundColor: AsteriaTheme.accentColor,
    elevation: AsteriaTheme.elevationHigh,
  ),
)
```

## 📱 Example App

Check out `theme_example.dart` for a complete working example with all components!

Run it to see the theme in action:
```dart
import 'theme_example.dart';

runApp(ThemeExampleApp());
```

---

**Need help?** The theme is built with Material 3 guidelines and uses warm, paper-inspired colors to create a friendly, inviting animated cartoon aesthetic. 🎨✨

