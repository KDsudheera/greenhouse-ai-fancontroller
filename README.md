# 🌱 Greenhouse AI Fan Controller

**Technical Interview Task - Embedded AI Developer Intern**

## 📋 Project Overview

This project implements an AI-powered greenhouse fan controller that:
- Analyzes temperature and humidity data using a trained machine learning model
- Simulates ESP32 + DHT22 + Relay system using PlatformIO and Wokwi
- Controls fan based on AI predictions via Firebase communication

## 🛠️ Implementation

### Part 1: AI Model Training ✅
- **File**: `grenhouse.ipynb` (Google Colab notebook)
- **Model**: `data/grenhouse_model.tflite` (2.8KB TensorFlow Lite model)
- **Accuracy**: 97.86% on test data
- **Input**: Temperature (°C) and Humidity (%)
- **Output**: Binary classification (Fan ON/OFF)

### Part 2: ESP32 Simulation ✅
- **Platform**: PlatformIO with Wokwi simulation
- **Hardware**: ESP32 + DHT22 sensor + Relay module
- **Functionality**:
  - Reads DHT22 every 10 seconds
  - Pushes data to Firebase `/climate_data`
  - Listens for commands at `/fan_on`
  - Controls relay based on received commands

### Part 3: Mobile App ⏳
- Flutter/Android app (in development)
- Real-time sensor data display
- On-device AI inference with .tflite model
- Firebase integration for control commands

## 🚀 Quick Start

### 1. Configure Firebase
1. Update `include/config.h` with your Firebase credentials:
   ```cpp
   #define API_KEY "your-api-key"
   #define DATABASE_URL "https://your-project-default-rtdb.firebaseio.com/"
   #define USER_EMAIL "your-email@example.com"
   #define USER_PASSWORD "your-password"
   ```

### 2. Upload to ESP32
```bash
pio run --target upload
pio device monitor
```

### 3. Test with Wokwi Simulation
- Open `diagram.json` in Wokwi
- Run simulation and monitor serial output
- Check Firebase console for data updates

## 📊 Firebase Data Structure

```json
{
  "climate_data": {
    "temperature_c": 25.5,
    "humidity_percent": 60.2,
    "timestamp": "1642678800",
    "fan_status": false
  },
  "fan_on": true
}
```

## 🔧 Hardware Configuration

- **ESP32 Dev Module**: Main microcontroller
- **DHT22 Sensor**: Connected to GPIO 4
- **Relay Module**: Connected to GPIO 5
- **Power**: 5V for relay, 3.3V for ESP32/DHT22

## 📈 Performance Metrics

- **Model Accuracy**: 97.86%
- **Response Time**: < 1 second
- **Memory Usage**: 84% Flash, 14.8% RAM
- **Update Interval**: 10 seconds (as required)

## 🎯 Task Compliance

✅ **Part 1 Complete**: AI model trained and exported to .tflite  
✅ **Part 2 Complete**: ESP32 simulation with Firebase integration  
⏳ **Part 3 In Progress**: Mobile app development  

## 📁 Project Structure

```
greenhouse-ai-fancontroller/
├── grenhouse.ipynb          # AI model training notebook
├── data/
│   └── grenhouse_model.tflite  # Trained model (2.8KB)
├── src/
│   └── main.cpp             # ESP32 main code
├── include/
│   ├── config.h             # Configuration file
│   └── config.h.example     # Template for credentials
├── diagram.json             # Wokwi simulation diagram
├── wokwi.toml              # Wokwi project configuration
└── platformio.ini          # PlatformIO configuration
```

## 🏆 Key Features

- **Robust Error Handling**: Network failures and sensor errors
- **Multiple Operation Modes**: AI predictions, manual control, offline mode
- **Real-time Monitoring**: Live data streaming to Firebase
- **Production Ready**: Watchdog timers and memory optimization
- **Configurable**: Easy credential and parameter management

---

**Submission Date**: 2025-08-07  
**Contact**: contact@zfrozen.com