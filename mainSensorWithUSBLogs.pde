#include <WaspSensorEvent_v20.h>
#include <WaspXBee802.h>

/* ----- Configuration ----- */

// Sensors Board
bool HAS_TEMPERATURE = true;
bool HAS_LUMINOSITY = true;
bool HAS_HUMIDITY = false;

// XBee Module
char COORDINATOR_ADDRESS[] = "0013A20041023C33";
int MAX_XBEE_SETUP_RETRY = 3; // Number of retries to boot the XBee module
int MAX_XBEE_SENDING_RETRY = 3; // Number of retries to send the frames to the coordinator
int PASSES_BEFORE_REBOOT = 12;
char SLEEP_TIME[] = "00:00:00:10";

// Variables
uint8_t battery;
int i, j, k;
int iteration = 6 - 1, passesBeforeSending = 0, passesBeforeReboot = 0;
float temperature[5], luminosity[5], humidity[5];
char temperatureBuf[10], luminosityBuf[10], humidityBuf[10], frame[6][50];

// Float to string conversion with 4 decimals precision
void ftoa(float f, char buf[]) {
  dtostrf(f, 1, 4, buf);
}

// Float array ascending sort
void ascSort(float f[]) {
  int a, b; float tmp;
  for (a = 0; a < 5; a++) {
    for (b = 0; b < 5; b++) {
      if (f[b] > f[a]) {
        tmp = f[a];
        f[a] = f[b];
        f[b] = tmp;
      }
    }
  }
}

// At Waspmote boot
void setup() {
  USB.println(F("Booting Waspmote..."));
  RTC.ON(); // Needed for sleeping
  USB.println(F("Booted."));
}

/* ----- Main Program ----- */

void loop() {

  USB.println(F("----- New loop -----"));

  /* ----- Gathering and Formatting Data ----- */

  USB.println(F("-> Gathering and formatting data"));

  battery = PWR.getBatteryLevel();

  USB.print(F("Battery : "));
  USB.println(battery, DEC);

  SensorEventv20.ON();

  // 5 consecutives sensor data are captured, then the average of the 3 median ones is kept
  if (HAS_TEMPERATURE) {
    for (i = 0; i < 5; i++) {
      delay(10);
      temperature[i] = SensorEventv20.readValue(SENS_SOCKET5, SENS_TEMPERATURE); // Socket 5 or 6
    }
    ascSort(temperature);
    ftoa((temperature[1] + temperature[2] + temperature[3]) / 3, temperatureBuf);
  } else { strcpy(temperatureBuf, "N\\A"); }

  USB.print(F("Temperature : "));
  USB.println(temperatureBuf);

  if (HAS_LUMINOSITY) {
    for (i = 0; i < 5; i++) {
      delay(10);
      luminosity[i] = SensorEventv20.readValue(SENS_SOCKET2, SENS_RESISTIVE); // Socket 1 (LL) or 2 or 3 (HL)
    }
    ascSort(luminosity);
    ftoa((luminosity[1] + luminosity[2] + luminosity[3]) / 3, luminosityBuf);
  } else { strcpy(luminosityBuf, "N\\A"); }

  USB.print(F("Luminosity : "));
  USB.println(luminosityBuf);

  if (HAS_HUMIDITY) {
    for (i = 0; i < 5; i++) {
      delay(10);
      humidity[i] = SensorEventv20.readValue(SENS_SOCKET6, SENS_HUMIDITY); // Socket 5 or 6
    }
    ascSort(humidity);
    ftoa((humidity[1] + humidity[2] + humidity[3]) / 3, humidityBuf);
  } else { strcpy(humidityBuf, "N\\A"); }

  USB.print(F("Humidity : "));
  USB.println(humidityBuf);

  SensorEventv20.OFF();

  // Storing sensor data in frame array
  sprintf(frame[passesBeforeSending], "%lu/%d/%s/%s/%s/%d",
    _serial_id, battery, temperatureBuf, luminosityBuf, humidityBuf, iteration);

  USB.print(F("Frame : "));
  USB.println(frame[passesBeforeSending]);

  passesBeforeSending++;
  iteration--;

  /* ----- Sending Data by ZigBee ----- */

  USB.print(F("Frames stored : "));
  USB.print(passesBeforeSending);
  USB.println(F("/6"));

  // Frames are stored before sending to avoid repetitive boots of XBee module
  if (passesBeforeSending == 6) {

    USB.println(F("-> Sending data by ZigBee"));

    // Activation with retries of XBee module

    USB.println(F("Booting XBee module..."));

    i = MAX_XBEE_SETUP_RETRY;
    while (xbee802.ON() != 0 && i > 0) {
      delay(10000);
      i--;

      USB.println(F("Retry... (10s)"));

    }

    // Activation of XBee module failed
    if (i == 0) {

      USB.println(F("XBee module failed to boot."));
      USB.println(F("Need to reboot Waspmote, the frames shall be lost."));
      USB.println(F("Rebooting Waspmote..."));

      PWR.reboot();

    }

    // Activated
    else if (i > 0) {

      USB.println(F("XBee module booted."));
      USB.println(F("Sending frames..."));

      // Sending with retries of the frames
      for (j = 0; j < 6; j++) {

        USB.print(F("Sending frame "));
        USB.print(j + 1);
        USB.println(F("/6..."));

        k = MAX_XBEE_SENDING_RETRY;
        while (xbee802.send(COORDINATOR_ADDRESS, frame[j]) != 0 && k > 0) {
          delay(5000);
          k--;

          USB.println(F("Retry... (5s)"));

        }

        if (k > 0) {

          USB.println(F("Frame sent."));

        }

        else if (k == 0) {

          USB.println(F("Frame unsent."));

        }

        USB.println(F("Waiting before sending next frame (5s)..."));

        delay(5000); // Delay before sending two different frames
      }

      USB.println(F("Turning off XBee module."));

      xbee802.OFF();
    }

    passesBeforeSending = 0;
    iteration = 6 - 1;

  }

  /* ----- Reboot Cycle ----- */

  // Rebooting after several loops is recommanded by the documentation to avoid various problems


  passesBeforeReboot++;

  USB.print(F("-> Reboot cycle ("));
  USB.print(passesBeforeReboot);
  USB.print(F("/"));
  USB.print(PASSES_BEFORE_REBOOT);
  USB.println(F(")"));

  if (passesBeforeReboot == PASSES_BEFORE_REBOOT) {

    USB.println(F("An entire cycle has already occured."));
    USB.println(F("Rebooting Waspmote..."));

    PWR.reboot();
  }

  /* ----- Sleeping ----- */

  USB.println(F("-> Sleeping"));
  USB.print(F("Wake up in "));
  USB.println(SLEEP_TIME);

  // Alarm1 Mode2 is for Date, Hour, Minutes, Seconds comparison with seconds precision
  PWR.deepSleep(SLEEP_TIME, RTC_OFFSET, RTC_ALM1_MODE2, ALL_OFF);

  USB.println(F("Awake."));

  // Clear interrupt flag, otherwise any future interruption wouldn't have been detected
  if (intFlag & RTC_INT) {
    RTC.clearAlarmFlag();
  }

}
