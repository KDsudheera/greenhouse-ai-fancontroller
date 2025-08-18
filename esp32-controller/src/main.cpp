#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include <time.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// WiFi credentials (for Wokwi simulation)
#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""

// Firebase configuration - load from config.h
#include "config.h"

#define USER_EMAIL "test@test.com"
#define USER_PASSWORD "test@123"
// Pin definitions
#define DHTPIN 15
#define DHTTYPE DHT22
#define RELAY_PIN 2

DHT dht(DHTPIN, DHTTYPE);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
bool fanStatus = false;

void setup() {
  Serial.begin(115200);
  
  // Initialize pins
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  
  // Initialize DHT sensor
  dht.begin();
  
  // Connect to WiFi
  Serial.println("Setting up WiFi...");
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  
  Serial.printf("Connecting to WiFi: %s\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  // Add timeout (30 seconds = 60 attempts * 500ms)
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 60) {
    Serial.print(".");
    delay(500);
    attempts++;
    
    // Debug WiFi status
    if (attempts % 10 == 0) {
      Serial.printf("\nWiFi Status: %d (attempt %d/60)\n", WiFi.status(), attempts);
    }
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.printf("IP Address: %s\n", WiFi.localIP().toString());
    Serial.printf("Signal Strength: %d dBm\n", WiFi.RSSI());
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    Serial.printf("Final WiFi Status: %d\n", WiFi.status());
    Serial.println("Continuing in offline mode...");
  }

  // Configure time sync (add this after WiFi connects successfully)
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  setenv("TZ", "UTC-5:30", 1);  // Change to your timezone
  tzset();

  Serial.println("Syncing time with NTP servers...");
  delay(2000);  // Wait for time sync
  
  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  
  // Use your existing user credentials
  auth.user.email = "test@test.com";
  auth.user.password = "test@123";
  
  // Set token status callback
  config.token_status_callback = tokenStatusCallback;
  
  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Wait for Firebase to be ready
  Serial.println("Waiting for Firebase to be ready...");
  while (!Firebase.ready()) {
    Serial.print(".");
    delay(1000);
  }
  Serial.println("\n✅ Firebase connected!");
  signupOK = true;
}

void loop() {
  // Check WiFi status and reconnect if needed
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected! Attempting to reconnect...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    int reconnect_attempts = 0;
    while (WiFi.status() != WL_CONNECTED && reconnect_attempts < 20) {
      Serial.print(".");
      delay(500);
      reconnect_attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nWiFi reconnected!");
    } else {
      Serial.println("\nWiFi reconnection failed, continuing offline...");
    }
  }
  
  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 10000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis() ;
  }
    
    // Read sensor data
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();
    
    // Simulate data if sensor reading fails (for Wokwi)
    if (isnan(humidity) || isnan(temperature)) {
      temperature = 25.0 + random(-100, 100) / 10.0;
      humidity = 60.0 + random(-200, 200) / 10.0;
      Serial.println("Using simulated data");
    }
    
    Serial.printf("Temperature: %.2f°C, Humidity: %.2f%%\n", 
                  temperature, humidity);
    
    // Only proceed with Firebase if WiFi is connected
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("No WiFi - skipping Firebase operations");
      return; // Exit loop early
    }

    // Send data to Firebase
    FirebaseJson json;
    json.add("temperature_c", temperature);
    json.add("humidity_percent", humidity);
    //Firebase.RTDB.setTimestamp(&fbdo, "/climate_data/timestamp");  // server time
    struct tm timeinfo;
    if (getLocalTime(&timeinfo)) {
      char timeString[16];
      strftime(timeString, sizeof(timeString), "%H:%M:%S", &timeinfo);
      json.add("timestamp", timeString);
    } else {
      json.add("timestamp", "00:00:00");  // Fallback if time not synced
  }
    json.add("fan_on", fanStatus);
    
    if (Firebase.RTDB.setJSON(&fbdo, "/climate_data", &json)) {
      Serial.println("Data sent to Firebase");
    } else {
      Serial.println("Failed to send data");
      Serial.println(fbdo.errorReason());
    }
    
    // Read fan control command
    if (Firebase.RTDB.getBool(&fbdo, "/fan_on")) {
      bool newFanStatus = fbdo.boolData();
      
      // Only change relay if status actually changed
      if (newFanStatus != fanStatus) {
        fanStatus = newFanStatus;
        digitalWrite(RELAY_PIN, fanStatus ? HIGH : LOW);
        Serial.printf("🌀 Fan Status changed to: %s\n", fanStatus ? "ON" : "OFF");
        
        // Update Firebase with current fan status
        if (Firebase.RTDB.setBool(&fbdo, "/current_fan_status", fanStatus)) {
          Serial.println("✅ Fan status updated in Firebase");
        } else {
          Serial.println("❌ Failed to update fan status in Firebase");
          Serial.println(fbdo.errorReason());
        }
      }
    } else {
      // Error handling for failed Firebase read
      Serial.println("❌ Failed to read fan command from Firebase");
      Serial.println(fbdo.errorReason());
    }
  } 
