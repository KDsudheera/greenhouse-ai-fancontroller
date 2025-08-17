# 🌱 Greenhouse AI Fan Controller

> **An intelligent IoT system that uses machine learning to automatically control greenhouse ventilation based on real-time temperature and humidity data**

[![Machine Learning](https://img.shields.io/badge/ML-TensorFlow%20Lite-orange)](https://tensorflow.org)
[![IoT](https://img.shields.io/badge/IoT-ESP32-blue)](https://www.espressif.com/en/products/socs/esp32)
[![Flutter](https://img.shields.io/badge/Mobile-Flutter-blue)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-yellow)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-PlatformIO-black)](https://platformio.org)
[![Simulator](https://img.shields.io/badge/Simulator-Wokwi-green)](https://wokwi.com)

## 📊 Project Overview

This project implements a complete AI-powered greenhouse fan control system with three main components:

1. **🧠 AI Model** - TensorFlow Lite model trained on 17,521 sensor samples
2. **🔧 ESP32 Controller** - Hardware simulation with real sensor integration
3. **📱 Flutter Mobile App** - Real-time monitoring and AI-powered control

### 🎯 Key Features

- **Intelligent Fan Control**: AI decides when to turn fan ON/OFF based on environmental conditions
- **Real-time Monitoring**: Live temperature and humidity tracking
- **Dual Control Modes**: AI automatic mode or manual override
- **Cloud Integration**: Firebase real-time database for seamless communication
- **Hardware Simulation**: Complete Wokwi simulation for testing without physical hardware
- **Production Ready**: Robust error handling and offline capabilities

## 🚀 Quick Demo

### Real-time AI Predictions:
```
🌡️ Temperature: 25.8°C | 💧 Humidity: 78.5%
🧠 AI Prediction: 0.387 (38.7% confidence) → 🌀 Fan: OFF

🌡️ Temperature: 32.1°C | 💧 Humidity: 85.2% 
🧠 AI Prediction: 0.782 (78.2% confidence) → 🌀 Fan: ON
```

### System Architecture:
```
📱 Flutter App          🔥 Firebase          🔧 ESP32 + Sensors
├── AI Model            ├── Real-time DB      ├── DHT22 (Temp/Humidity)
├── Dashboard UI        ├── Authentication    ├── Relay Module (Fan)
├── Manual Controls     └── Data Sync         └── WiFi Connection
└── Live Monitoring     ↕️ Bidirectional      ↕️ Sensor Data
```

## 🛠️ How to Run This Project

### Prerequisites

1. **Development Environment:**
   - [Visual Studio Code](https://code.visualstudio.com/) with PlatformIO extension
   - [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
   - [Firebase CLI](https://firebase.google.com/docs/cli) (optional)
   - [Git](https://git-scm.com/)

2. **Hardware (Optional - for physical deployment):**
   - ESP32 Development Board
   - DHT22 Temperature/Humidity Sensor
   - 5V Relay Module
   - Jumper wires and breadboard

### Step 1: Clone the Repository

```bash
git clone https://github.com/KDsudheera/greenhouse-ai-fancontroller.git
cd greenhouse-ai-fancontroller
```

### Step 2: Set Up Firebase

1. **Create Firebase Project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Create a project"
   - Enable **Realtime Database** (start in test mode)
   - Enable **Authentication** → **Email/Password**

2. **Configure Firebase for Flutter:**
   ```bash
   cd flutter_app
   
   # Install Firebase CLI (if not installed)
   npm install -g firebase-tools
   
   # Login and configure
   firebase login
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

3. **Set up Database Rules:**
   ```json
   {
     "rules": {
       ".read": "auth != null",
       ".write": "auth != null"
     }
   }
   ```

### Step 3: Configure ESP32 Credentials

1. **Copy the example config:**
   ```bash
   cd esp32-controller
   cp include/config.h.example include/config.h
   ```

2. **Edit `include/config.h` with your credentials:**
   ```cpp
   // WiFi Configuration
   #define WIFI_SSID "your-wifi-name"
   #define WIFI_PASSWORD "your-wifi-password"
   
   // Firebase Configuration  
   #define API_KEY "your-firebase-api-key"
   #define DATABASE_URL "https://your-project-default-rtdb.firebaseio.com/"
   #define USER_EMAIL "your-email@example.com"
   #define USER_PASSWORD "your-password"
   ```

### Step 4: Run the ESP32 Simulation

1. **Using Wokwi (Recommended for testing):**
   ```bash
   cd esp32-controller
   
   # Upload to Wokwi and run simulation
   # Open diagram.json in Wokwi.com
   # Click "Start Simulation"
   ```

2. **Using Physical Hardware:**
   ```bash
   cd esp32-controller
   
   # Compile and upload
   pio run --target upload
   
   # Monitor serial output
   pio device monitor
   ```

### Step 5: Run the Flutter App

1. **Install dependencies:**
   ```bash
   cd flutter_app
   flutter pub get
   ```

2. **Run on Android device/emulator:**
   ```bash
   # Check connected devices
   flutter devices
   
   # Run the app
   flutter run
   ```

3. **Enable Developer Options (for physical device):**
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"

### Step 6: Test the Complete System

1. **Verify ESP32 Connection:**
   - Check serial monitor for "Connected to Firebase"
   - Verify sensor readings in console

2. **Check Firebase Data:**
   - Open Firebase Console → Realtime Database
   - Look for `/climate_data` updates every 10 seconds

3. **Test Flutter App:**
   - Open the app and verify real-time data display
   - Toggle between AI mode and Manual mode
   - Check AI predictions in the console

## 📁 Project Structure

```
greenhouse-ai-fancontroller/
├── README.md                           # This file
├── esp32-controller/                   # ESP32 microcontroller code
│   ├── src/main.cpp                   # Main ESP32 application
│   ├── include/
│   │   ├── config.h.example           # Configuration template
│   │   └── README                     # Include directory info
│   ├── data/
│   │   └── grenhouse_model.tflite     # AI model for ESP32 (backup)
│   ├── platformio.ini                 # PlatformIO configuration
│   ├── diagram.json                   # Wokwi simulation diagram
│   └── wokwi.toml                     # Wokwi project settings
├── flutter_app/                       # Mobile application
│   ├── lib/
│   │   ├── main.dart                  # Main Flutter app
│   │   ├── firebase_options.dart      # Firebase configuration
│   │   └── [models/screens/services/] # App architecture (future)
│   ├── assets/
│   │   └── grenhouse_model.tflite     # AI model for mobile inference
│   ├── android/                       # Android-specific configuration
│   ├── pubspec.yaml                   # Flutter dependencies
│   └── firebase.json                  # Firebase project settings
├── docs/
│   └── greenhouse.ipynb               # AI model training notebook
└── assets/                           # Additional project assets
```

## 🧠 AI Model Details

### Training Data
- **Dataset Size:** 17,521 samples
- **Features:** Temperature (20.9°C - 90.5°C), Humidity (31.69% - 100%)
- **Target:** Binary classification (Fan ON/OFF)
- **Training Method:** Google Colab with TensorFlow

### Model Architecture
```python
model = Sequential([
    Dense(16, activation='relu', input_shape=(2,)),
    Dense(8, activation='relu'),
    Dense(1, activation='sigmoid')
])
```

### Performance Metrics
- **Accuracy:** 98% on test data
- **Model Size:** 2KB (optimized for mobile)
- **Inference Time:** <10ms on mobile device
- **Real-world Validation:** Excellent uncertainty handling

### Normalization (Important!)
```python
# Input normalization used in training
temperature_normalized = (temp - 20.9) / (90.5 - 20.9)
humidity_normalized = (humidity - 31.69) / (100.0 - 31.69)
```

## 🔧 Hardware Configuration

### Wokwi Simulation (Default)
- **ESP32 DevKit V1**
- **DHT22 Sensor** → GPIO 4
- **LED (Fan Indicator)** → GPIO 5
- **WiFi Connection** → Simulated

### Physical Hardware Setup
```
ESP32 DevKit V1:
├── DHT22 Sensor
│   ├── VCC → 3.3V
│   ├── GND → GND
│   └── DATA → GPIO 4
├── Relay Module (Fan Control)
│   ├── VCC → 5V
│   ├── GND → GND
│   └── IN → GPIO 5
└── Power Supply → USB/External 5V
```

## 🔥 Firebase Data Structure

### Real-time Database Schema
```json
{
  "climate_data": {
    "temperature_c": 25.8,
    "humidity_percent": 78.5,
    "timestamp": "1642678800",
    "fan_status": false,
    "last_updated": "2025-01-15T10:30:00Z"
  },
  "fan_on": true,
  "current_fan_status": false,
  "ai_predictions": {
    "last_confidence": 0.387,
    "last_decision": "OFF",
    "prediction_count": 1247
  }
}
```

### Security Rules
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "climate_data": {
      ".validate": "newData.hasChildren(['temperature_c', 'humidity_percent'])"
    }
  }
}
```

## 📱 Flutter App Features

### Main Dashboard
- **Real-time Sensor Data:** Live temperature and humidity display
- **AI Prediction Status:** Current confidence level and decision
- **Fan Control:** Manual override toggle
- **Connection Status:** ESP32 and Firebase connectivity indicators

### AI Integration
- **On-device Inference:** TensorFlow Lite model runs locally
- **Uncertainty Handling:** Shows confidence levels (0.3-0.7 typical)
- **Smart Decisions:** Appropriate hesitation in borderline conditions

### User Interface
```dart
// Key UI Components
├── Temperature Card → Real-time display with trend
├── Humidity Card → Percentage with visual indicator  
├── AI Status Card → Prediction confidence and decision
├── Fan Control Toggle → Manual override capability
└── Connection Status → System health indicators
```

## 🔍 Troubleshooting

### Common Issues

1. **ESP32 Won't Connect to WiFi:**
   ```cpp
   // Check config.h credentials
   // Verify WiFi network is 2.4GHz (not 5GHz)
   // Check serial monitor for connection attempts
   ```

2. **Firebase Authentication Fails:**
   ```bash
   # Verify credentials in config.h
   # Check Firebase Console → Authentication → Users
   # Ensure email/password auth is enabled
   ```

3. **Flutter Build Errors:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **AI Model Not Loading:**
   ```bash
   # Verify grenhouse_model.tflite exists in flutter_app/assets/
   # Check pubspec.yaml has assets configuration
   # Confirm file path in main.dart
   ```

### Performance Optimization

1. **ESP32 Memory Issues:**
   - Monitor serial output for heap usage
   - Reduce Firebase update frequency if needed
   - Enable watchdog timer for stability

2. **Flutter Performance:**
   - Use release build for production: `flutter run --release`
   - Monitor AI inference time in debug logs
   - Optimize Firebase listeners

## 📊 Performance Metrics

### System Performance
- **Response Time:** < 1 second from sensor to AI decision
- **Update Frequency:** 10 seconds (configurable)
- **Memory Usage:** 
  - ESP32: 84% Flash, 14.8% RAM
  - Flutter: ~50MB with TensorFlow Lite
- **Power Consumption:** Optimized with smart fan control

### AI Model Performance
- **Training Accuracy:** 98%
- **Real-world Confidence Range:** 0.3-0.7 (realistic uncertainty)
- **Inference Speed:** <10ms on mobile
- **Model Size:** 2KB (efficient for IoT deployment)

## 🎯 Use Cases

### Educational Applications
- **IoT Development:** Complete embedded system with cloud integration
- **Machine Learning:** Real-world AI deployment on mobile devices
- **Flutter Development:** Professional mobile app with real-time features
- **Firebase Integration:** Modern backend-as-a-service implementation

### Practical Applications
- **Greenhouse Automation:** Actual agricultural use
- **Home Automation:** Smart ventilation control
- **Research Projects:** Environmental monitoring system
- **Portfolio Projects:** Demonstrates full-stack IoT capabilities

## 🚀 Future Enhancements

### Potential Improvements
- [ ] **Multi-sensor Support:** Add soil moisture, light sensors
- [ ] **Data Analytics:** Historical trends and insights
- [ ] **Push Notifications:** Alert system for critical conditions
- [ ] **Schedule Control:** Time-based automation rules
- [ ] **Energy Monitoring:** Track power consumption
- [ ] **Multiple Zones:** Control multiple greenhouse sections

### Advanced Features
- [ ] **Edge AI:** Run AI model on ESP32 directly
- [ ] **Over-the-Air Updates:** Remote firmware updates
- [ ] **Mesh Networking:** Multiple ESP32 communication
- [ ] **Voice Control:** Integration with smart assistants

## 📖 Citation

If you use this project in your research or commercial applications, please cite:

```
Greenhouse AI Fan Controller
https://github.com/KDsudheera/greenhouse-ai-fancontroller
An intelligent IoT system using machine learning for greenhouse automation
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Contact & Support

- **GitHub:** [@KDsudheera](https://github.com/KDsudheera)
- **Email:** contact@zfrozen.com
- **Project Issues:** [GitHub Issues](https://github.com/KDsudheera/greenhouse-ai-fancontroller/issues)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎉 Acknowledgments

- **TensorFlow Team** for TensorFlow Lite mobile inference
- **Firebase Team** for real-time database services
- **Flutter Team** for cross-platform mobile development
- **PlatformIO Team** for embedded development platform
- **Wokwi Team** for excellent hardware simulation

---

## ⭐ If This Project Helped You

If this project was useful for your learning or development:

- ⭐ **Star this repository**
- 🔄 **Share with others interested in IoT + AI**
- 🐛 **Report issues** to help improve the project
- 🤝 **Contribute** improvements or new features

---

**Built with ❤️ for the IoT and AI community**

*"Smart agriculture starts with intelligent automation"* 🌱🤖