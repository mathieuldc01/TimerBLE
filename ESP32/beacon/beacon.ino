#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLEAdvertising.h>

// ================= DEVICE NAME =================
#define DEVICE_NAME "ESP32_BEACON"

// ================= SETUP =================
void setup() {

  Serial.begin(115200);
  delay(1000);

  Serial.println("[BEACON] START");

  BLEDevice::init(DEVICE_NAME);

  BLEServer* pServer = BLEDevice::createServer();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();

  // ================= ADVERTISING PAYLOAD =================
  BLEAdvertisementData advData;
  advData.setName(DEVICE_NAME);

  // (optionnel) custom data
  advData.setManufacturerData("ESP32_FAST");

  pAdvertising->setAdvertisementData(advData);

  // ================= FAST ADVERTISING SETTINGS =================

  // interval = 20ms min practical ESP32 BLE
  pAdvertising->setMinInterval(0x0020); // 20 ms
  pAdvertising->setMaxInterval(0x0030); // ~30 ms

  // IMPORTANT: reduce latency
  pAdvertising->setMinPreferred(0x20);
  pAdvertising->setMaxPreferred(0x30);

  // advertising type
  pAdvertising->setScanResponse(false);

  // start
  pAdvertising->start();

  Serial.println("[BEACON] ADVERTISING FAST MODE");
}

// ================= LOOP =================
void loop() {

  // rien à faire, advertising hardware
  delay(1000);
}
