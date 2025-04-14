
# 😄✨ Face Condition Detection

Welcome to **Face Condition Detection** — a smart and friendly **Flutter** app that turns your device into a real-time emotion reader!  
Using **Google ML Kit**, it detects faces, reads moods, and adapts to different lighting environments — whether you're basking in the sun or curled up in low light.

---

## 🎯 Features

✨ Real-time camera-based emotion detection  
😎 Detects multiple faces simultaneously  
🔆 Adjusts to lighting conditions on the fly  
🧠 Mood analysis via smiles and eye movements  
🎨 Clean, dark-themed UI for a sleek user experience  
📱 Android-first (iOS coming soon!)

---

## 🚀 Getting Started

### 🔧 Prerequisites

- ✅ [Flutter SDK 3.0+](https://flutter.dev/docs/get-started/install)  
- ✅ Android device or emulator (iOS requires Xcode + Mac)  
- ✅ Camera access  

### 📥 Installation

```bash
git clone https://github.com/Suhani-Singh95/face-condition-detection.git
cd face-condition-detection
flutter pub get
flutter doctor
flutter run
```

Ensure your device or emulator is connected, and **grant camera permissions**.

### 📸 Permissions

- **Android**: `android/app/src/main/AndroidManifest.xml` → `CAMERA`
- **iOS**: `ios/Runner/Info.plist` → `NSCameraUsageDescription`

---

## 🔍 How It Works

### 🧰 Tech Stack

- **Flutter** – Cross-platform UI  
- **Google ML Kit** – Face detection & emotion insights  
- **Camera package** – Captures real-time frames

### 🧪 Features in Action

- Every 3rd frame is analyzed for balance of **speed & accuracy**  
- **Mood detection** using `smileProbability` and `eyeOpenProbability`  
- **Auto-exposure adjustment** for lighting estimation  
- Privacy-friendly: Images are processed in-memory, **not stored**

---

## 🔮 What’s Next?

Here’s what’s on the roadmap:

- ☕ Smarter mood categories (like “Needs Coffee” 😴)  
- ☁️ Cloud sync and mood tracking over time  
- 😍 Mood-based UI animations or emoji overlays

Got cool ideas? Open an issue or pull request — contributions are super welcome!

---

## 🤝 Contributing

1. Fork this repo  
2. Create your branch: `git checkout -b feature-name`  
3. Commit your changes: `git commit -m "Add: new feature"`  
4. Push and open a PR  

> A detailed CONTRIBUTING.md will be added soon!

---

## 🐞 Found a Bug?

Please include:
- Description of what went wrong  
- Logs if possible  
- Your OS, Flutter version, and device  

---

## 💬 Connect with Me

Hi, I'm **Suhani Singh** 👋  
Let’s talk about this app or anything tech!

[![LinkedIn](https://img.shields.io/badge/LinkedIn-blue?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/suhani-singh9523/)  
[![GitHub](https://img.shields.io/badge/GitHub-000?style=flat-square&logo=github)](https://github.com/Suhani-Singh95)

---

> Built with 💖 using Flutter & ML Kit by Suhani Singh
