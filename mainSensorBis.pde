#include <WaspSensorEvent_v20.h>
#include <WaspXBee802.h>

/* ----- Configuration ----- */

#define USB_LOGS 1 // 0 : No log, 1 : Descriptives logs, 2 : Verbose

// Sensors Board
bool SB_HAS_TEMPERATURE = true;
bool SB_HAS_LUMINOSITY = true;
bool SB_HAS_HUMIDITY = false;

// XBee Module
char* XBEE_COORDINATOR_ADDRESS = "0013A20041023C33";
int XBEE_MAX_CONNECTION_RETRY = 2;
int XBEE_DELAY_BETWEEN_CONNECTION_RETRY = 5000;
int XBEE_MAX_SUBROUTINE_RETRY = 10;
int XBEE_DELAY_BETWEEN_SENDING_RETRY = 5000;
int XBEE_PASSES_BEFORE_REBOOT = 36;

// Others
char* SLEEP_TIME = "00:00:10:00";
int LISTENING_TIME = 10000;

// Variables
uint8_t battery, receive;
int i, k, answer;
int passesBeforeReboot = 0;
float temperature[5], luminosity[5], humidity[5];
char temperatureBuf[10], luminosityBuf[10], humidityBuf[10], frame[50];
bool keep;

// Float array ascending sort
void ascSort(float f[]) {
  int a, b; float tmp;
  for (a = 0; a < sizeof(f); a++)
    for (b = 0; b < sizeof(f); b++)
      if (f[b] > f[a]) {
        tmp = f[a];
        f[a] = f[b];
        f[b] = tmp;
      }
}

// At Waspmote boot
void setup() {

  #if USB_LOGS > 0
  USB.println(F("Setup :"));
  USB.println(F(" > Booting Waspmote ..."));
  #endif

  RTC.ON(); // Needed for sleeping

  #if USB_LOGS > 0
  USB.println(F(" > Waspmote booted."));
  #endif

}

/* ----- Main Program ----- */

void loop() {

  /* ----- Sensors and Data ----- */

  #if USB_LOGS > 0
  USB.println(F("----- New loop -----"));
  USB.println(F("Data :"));
  #endif

  battery = PWR.getBatteryLevel();

  SensorEventv20.ON();

  // 5 consecutives sensor data are captured, then the average of the 3 median ones is kept
  if (SB_HAS_TEMPERATURE) {

    #if USB_LOGS > 1
    USB.print(F(" > Temperature : "));
    #endif

    for (i = 0; i < 5; i++) {

      delay(500);
      temperature[i] = SensorEventv20.readValue(SENS_SOCKET5, SENS_TEMPERATURE); // Socket 5 or 6

      #if USB_LOGS > 1
      USB.print(temperature[i]);
      USB.print(" ");
      #endif

    }

    #if USB_LOGS > 1
    USB.println();
    #endif

    ascSort(temperature);
    dtostrf((temperature[1] + temperature[2] + temperature[3]) / 3, 1, 1, temperatureBuf);

  } else { strcpy(temperatureBuf, "N\\A"); }

  if (SB_HAS_LUMINOSITY) {

    #if USB_LOGS > 1
    USB.print(F(" > Luminosity : "));
    #endif

    for (i = 0; i < 5; i++) {

      delay(500);
      luminosity[i] = SensorEventv20.readValue(SENS_SOCKET2, SENS_RESISTIVE); // Socket 1 (LL) or 2 or 3 (HL)

      #if USB_LOGS > 1
      USB.print(luminosity[i]);
      USB.print(" ");
      #endif

    }

    #if USB_LOGS > 1
    USB.println();
    #endif

    ascSort(luminosity);
    dtostrf((luminosity[1] + luminosity[2] + luminosity[3]) / 3, 1, 1, luminosityBuf);

  } else { strcpy(luminosityBuf, "N\\A"); }

  if (SB_HAS_HUMIDITY) {

    #if USB_LOGS > 1
    USB.print(F(" > Humidity : "));
    #endif

    for (i = 0; i < 5; i++) {

      delay(500);
      humidity[i] = SensorEventv20.readValue(SENS_SOCKET6, SENS_HUMIDITY); // Socket 5 or 6

      #if USB_LOGS > 1
      USB.print(humidity[i]);
      USB.print(" ");
      #endif

    }

    #if USB_LOGS > 1
    USB.println();
    #endif

    ascSort(humidity);
    dtostrf((humidity[1] + humidity[2] + humidity[3]) / 3, 1, 1, humidityBuf);

  } else { strcpy(humidityBuf, "N\\A"); }

  #if USB_LOGS > 0
  USB.print(F(" > Battery : "));
  USB.println(battery, DEC);

  USB.print(F(" > Temperature : "));
  USB.println(temperatureBuf);

  USB.print(F(" > Luminosity : "));
  USB.println(luminosityBuf);

  USB.print(F(" > Humidity : "));
  USB.println(humidityBuf);
  #endif

  SensorEventv20.OFF();

  // Storing sensor data in frame array
  sprintf(frame, "%lu/%d/%s/%s/%s",
    _serial_id, battery, temperatureBuf, luminosityBuf, humidityBuf);

  #if USB_LOGS > 0
  USB.print(F(" > Frame : "));
  USB.println(frame);
  #endif

  /* ----- Sending Data ----- */

  #if USB_LOGS > 0
  USB.println(F("Sending data : "));
  USB.println(F(" > Booting XBee module ..."));
  #endif

  // Activation with retries of XBee module
  i = XBEE_MAX_CONNECTION_RETRY;
  while (xbee802.ON() != 0 && i > 0) {

    #if USB_LOGS > 0
    USB.print(F(" > > Error. Retry in "));
    USB.print(XBEE_DELAY_BETWEEN_CONNECTION_RETRY / 1000);
    USB.println(F("s ..."));
    #endif

    delay(XBEE_DELAY_BETWEEN_CONNECTION_RETRY);
    i--;

  }

  // Activation of XBee module failed
  if (i == 0) {

    #if USB_LOGS > 0
    USB.println(F(" > XBee module failed to boot."));
    USB.println(F(" > Rebooting Waspmote ..."));
    #endif

    PWR.reboot();

  }

  // XBee module activated
  else if (i > 0) {

    #if USB_LOGS > 0
    USB.println(F(" > XBee module booted."));
    USB.println(F(" > Sending frame ..."));
    #endif

    // Sending with retries of the frame
    k = XBEE_MAX_SUBROUTINE_RETRY;
    keep = false;

    do {

      answer = xbee802.send(XBEE_COORDINATOR_ADDRESS, frame);

      if (answer != 0) {

        #if USB_LOGS > 0
        USB.print(F(" > > Error. Retry in "));
        USB.print(XBEE_DELAY_BETWEEN_SENDING_RETRY / 1000);
        USB.println(F("s ..."));
        #endif

        delay(XBEE_DELAY_BETWEEN_SENDING_RETRY);
        k--;

      }

      else if (answer == 0) {

        delay(50);

        #if USB_LOGS > 0
        USB.println(F(" > Listening for confirmation ..."));
        #endif

        receive = xbee802.receivePacketTimeout(LISTENING_TIME);

        if (receive == 0) {

          #if USB_LOGS > 1
          USB.print(F(" > Confirmation packet : "));
          USB.println(xbee802._payload, xbee802._length);
          USB.print(F(" > Confirmation packet length : "));
          USB.println(xbee802._length, DEC);
          USB.print(F(" > Confirmation packet MAC : "));
          for (i = 0; i < 8; i++) {
            USB.printHex(xbee802._srcMAC[i]);
          }
          USB.println();
          #endif

          if (((int) xbee802._length) == 2) {

            #if USB_LOGS > 0
            USB.println(F(" > Confirmation received."));
            #endif

            keep = true;

          }

        }

      }

    } while (!keep && k > 0);

    if (keep && k > 0) {

      #if USB_LOGS > 0
      USB.println(F(" > Frame sent."));
      #endif

    }

    else if (k == 0) {

      #if USB_LOGS > 0
      USB.println(F(" > Frame not sent."));
      USB.println(F(" > Rebooting Waspmote ..."));
      #endif

      PWR.reboot();

    }

    #if USB_LOGS > 0
    USB.println(F(" > XBee module turned off."));
    #endif

    xbee802.OFF();

  }

  /* ----- Reboot Cycle ----- */

  // Rebooting after several loops is recommanded by the documentation to avoid various problems
  passesBeforeReboot++;

  #if USB_LOGS > 1
  USB.print(F(" > Reboot cycle ("));
  USB.print(passesBeforeReboot);
  USB.print(F("/"));
  USB.print(XBEE_PASSES_BEFORE_REBOOT);
  USB.println(F(")"));
  #endif

  if (passesBeforeReboot == XBEE_PASSES_BEFORE_REBOOT) {

    #if USB_LOGS > 0
    USB.println(F("Reboot :"));
    USB.println(F(" > An entire cycle has already occured."));
    USB.println(F(" > Rebooting Waspmote..."));
    #endif

    PWR.reboot();

  }

  /* ----- Sleeping ----- */

  #if USB_LOGS > 0
  USB.println(F("Sleeping :"));
  USB.print(F(" > Wake up set in "));
  USB.println(SLEEP_TIME);
  USB.println(F(" > Sleeping ..."));
  #endif

  // Alarm1 Mode2 is for Date, Hour, Minutes, Seconds comparison with seconds precision
  PWR.deepSleep(SLEEP_TIME, RTC_OFFSET, RTC_ALM1_MODE2, ALL_OFF);

  #if USB_LOGS > 0
  USB.println(F(" > Waking up."));
  #endif

  // Clear interrupt flag, otherwise any future interruption wouldn't have been detected
  if (intFlag & RTC_INT) {

    RTC.clearAlarmFlag();

  }

}
