#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEScan.h>
#include <BLEUtils.h>
#include <BLECharacteristic.h>
#include <BLE2902.h>
#include <Adafruit_NeoPixel.h>
#include "esp_sleep.h"

// ================= UUID =================
#define SERVICE_UUID "12345678-1234-1234-1234-1234567890ab"
#define CHAR_TX_UUID "abcd1234-1234-1234-1234-abcdef123456"
#define CHAR_RX_UUID "dcba4321-4321-4321-4321-654321fedcba"

// ================= HARDWARE =================
#define BUTTON_PIN 4
#define LED_PIN 48

Adafruit_NeoPixel led(1, LED_PIN, NEO_GRB + NEO_KHZ800);

// ================= LED =================
void setColor(int r, int g, int b) {
  led.setPixelColor(0, led.Color(r, g, b));
  led.show();
}

// ================= STATE =================
unsigned long pressStart = 0;
bool buttonPressed = false;
bool pendingSleep = false;

int mode = 0;
const int maxModes = 2;

BLEServer* pServer = nullptr;
BLEService* pService = nullptr;
BLEAdvertising* pAdvertising = nullptr;

BLECharacteristic* txChar = nullptr;
BLECharacteristic* rxChar = nullptr;

BLEScan* pBLEScan = nullptr;

bool scanActive = false;
bool advActive = false;
bool deviceConnected = false;

// ================= DETECTIONS =================
struct Detection {
  uint32_t ts;
  int rssi;
  std::string addr;   // ici tu stockes le nom (ESP32_xxx)
};

#define MAX_DETECTIONS 200

Detection detections[MAX_DETECTIONS];
int detectIndex = 0;

// ================= ADD DETECTION =================
void addDetection(uint32_t ts, int rssi, std::string addr) {
  detections[detectIndex] = { ts, rssi, addr };

  detectIndex++;
  if (detectIndex >= MAX_DETECTIONS) {
    detectIndex = 0;
  }

  Serial.print("[DETECT] ");
  Serial.print(addr.c_str());
  Serial.print(" RSSI=");
  Serial.println(rssi);
}

// ================= SCAN CALLBACK =================
class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice d) override {
    std::string name = d.getName();

    if (!name.empty() && name.rfind("ESP32_", 0) == 0) {
      addDetection(
        millis(),
        d.getRSSI(),
        d.getName()   // on stocke le nom du device
      );

      setColor(60, 0, 60);
    }
  }
};

// ================= START SCAN =================
void startScan() {
  if (scanActive) return;

  Serial.println("[SCAN] START");

  pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setActiveScan(true);
  pBLEScan->setInterval(50);
  pBLEScan->setWindow(45);
  pBLEScan->start(0, nullptr, false);

  scanActive = true;
  setColor(255, 255, 255);
}

// ================= STOP SCAN =================
void stopScan() {
  if (!scanActive) return;

  Serial.println("[SCAN] STOP");

  pBLEScan->stop();
  pBLEScan->clearResults();

  scanActive = false;
}

// ================= RX CALLBACK =================
class MyRXCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) override {
    std::string value = pChar->getValue();

    Serial.print("[RX] ");
    Serial.println(value.c_str());

    // ================= GET_ALL =================
    if (value.find("GET_ALL") != std::string::npos) {
      Serial.println("[BLE] SEND ALL");

      std::string bigData = "";
      bool hasData = false;

      for (int i = 0; i < MAX_DETECTIONS; i++) {
        Detection d = detections[i];
        if (d.addr.empty()) continue;

        hasData = true;

        char buf[120];
        snprintf(
          buf,
          sizeof(buf),
          "ts=%lu,addr=%s,rssi=%d\n",
          d.ts,
          d.addr.c_str(),
          d.rssi
        );
        bigData += buf;
      }

      if (!hasData) {
        bigData = "NO_DATA\n";
      }

      const int chunkSize = 180;
      for (int i = 0; i < (int)bigData.length(); i += chunkSize) {
        std::string chunk = bigData.substr(i, chunkSize);

        Serial.print("[TX CHUNK] ");
        Serial.println(chunk.c_str());

        txChar->setValue(chunk);
        txChar->notify();
        delay(100);
      }

      txChar->setValue("END\n");
      txChar->notify();

      Serial.println("[BLE] END");
    }

    // ================= DISCONNECT =================
    if (value.find("DISCONNECT") != std::string::npos) {
      Serial.println("[BLE] DISCONNECT CMD");

      delay(100);
      deviceConnected = false;

      // on coupe / relance l'advertising proprement
      if (pAdvertising) {
        pAdvertising->stop();
        delay(100);
        pAdvertising->start();
      }

      Serial.println("[BLE] READY FOR RECONNECT");
    }
  }
};

// ================= SERVER CALLBACK =================
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("[BLE] CONNECTED");
    setColor(0, 255, 0);
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("[BLE] DISCONNECTED");

    // reset detections
    for (int i = 0; i < MAX_DETECTIONS; i++) {
      detections[i].addr = "";
    }
    detectIndex = 0;

    setColor(255, 0, 0);
    pendingSleep = true;
  }
};

// ================= INIT GATT (UNE SEULE FOIS) =================
void initGATT() {
  Serial.println("[GATT] INIT");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  pService = pServer->createService(SERVICE_UUID);

  // TX
  txChar = pService->createCharacteristic(
    CHAR_TX_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  txChar->addDescriptor(new BLE2902());

  // RX
  rxChar = pService->createCharacteristic(
    CHAR_RX_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  rxChar->setCallbacks(new MyRXCallbacks());

  pService->start();

  pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);

  Serial.println("[GATT] READY");
}

// ================= START / STOP ADVERTISING =================
void startGATT() {
  if (advActive) return;
  if (!pAdvertising) return;

  Serial.println("[GATT] ADVERTISING START");
  pAdvertising->start();
  advActive = true;
  setColor(0, 255, 0);
}

void stopGATT() {
  if (!advActive) return;
  if (!pAdvertising) return;

  Serial.println("[GATT] ADVERTISING STOP");
  pAdvertising->stop();
  advActive = false;
}

// ================= SLEEP =================
void goToSleep() {
  Serial.println("[SLEEP]");

  setColor(0, 0, 0);

  stopScan();
  stopGATT();

  BLEDevice::deinit(true);
  delay(200);

  esp_sleep_enable_ext0_wakeup(GPIO_NUM_4, 0);
  esp_deep_sleep_start();
}

// ================= SETUP =================
unsigned long lastScan = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);

  led.begin();
  led.setBrightness(20);

  pinMode(BUTTON_PIN, INPUT_PULLUP);
  setColor(0, 0, 255);

  // clear detections
  for (int i = 0; i < MAX_DETECTIONS; i++) {
    detections[i].addr = "";
  }

  BLEDevice::init("ESP32_SCANNER");

  initGATT();   // ✅ une seule fois
  startScan();  // mode 0 par défaut
}

// ================= LOOP =================
void loop() {
  int buttonState = digitalRead(BUTTON_PIN);

  // ================= BUTTON =================
  if (buttonState == LOW) {
    if (!buttonPressed) {
      pressStart = millis();
      buttonPressed = true;
    }
  } else {
    if (buttonPressed) {
      unsigned long duration = millis() - pressStart;

      // LONG PRESS -> SLEEP
      if (duration > 5000) {
        goToSleep();
      }
      // SHORT PRESS -> CHANGE MODE
      else if (duration > 200) {
        mode++;
        if (mode >= maxModes) mode = 0;

        Serial.print("[MODE] ");
        Serial.println(mode);
      }

      buttonPressed = false;
    }
  }

  // ================= MODE 0 = SCAN =================
  if (mode == 0) {
    if (!scanActive) {
      stopGATT();   // on coupe l'advertising
      startScan();  // on scanne
    }

    if (scanActive && millis() - lastScan >= 100) {
      lastScan = millis();
      // HARD REFRESH SCAN
      pBLEScan->stop();
      pBLEScan->start(0, nullptr, false);
    }
  }

  // ================= MODE 1 = GATT =================
  if (mode == 1) {
    if (!advActive) {
      stopScan();   // on arrête le scan
      startGATT();  // on démarre l'advertising
    }
  }

  if (pendingSleep) {
    pendingSleep = false;
    Serial.println("[SLEEP AFTER DISCONNECT]");
    delay(500);
    goToSleep(); // tu peux le réactiver si tu veux
  }

  delay(10);
}
