#include <WaspXBee802.h>
#include <Wasp3G.h>

/* ----- Configuration ----- */

#define USB_LOGS 1 // 0 : No log, 1 : Descriptives logs, 2 : Verbose

// XBee Module
int XBEE_MAX_SUBROUTINE_TRY = 2;
int XBEE_DELAY_BETWEEN_SUBROUTINE_RETRY = 5000;

// 3G Module
char* _3G_APN_NAME = "free";
char* _3G_SIM_PIN = "1234";
int _3G_MAX_SUBROUTINE_TRY = 2;
int _3G_DELAY_BETWEEN_SUBROUTINE_RETRY = 3000;
char* _3G_WEB_SERVER_IP = "31.35.122.165"; // Paul : 92.167.78.214, Ju : 31.35.122.165

// Others
char* TIME_BEFORE_REBOOT = "23:59:00:00";
uint32_t LISTENING_TIME = 60000;

// Variables
int i;
uint8_t answer, confirmation;
char packet[100], frame[100], packetScratched[5][10];
char* subPacket;

// At Waspmote boot
void setup() {

  #if USB_LOGS > 0
  USB.println(F("Setup :"));
  USB.println(F(" > Booting Waspmote ..."));
  #endif

  RTC.ON(); // Needed for sleeping after failure to connect 3G

  // ZigBee

  #if USB_LOGS > 0
  USB.println(F(" > > Booting XBee module ..."));
  #endif

  // Activation with retries of XBee module
  i = XBEE_MAX_SUBROUTINE_TRY;
  while (xbee802.ON() != 0 && i > 0) {

    #if USB_LOGS > 0
    USB.print(F(" > > > Error. Retry in "));
    USB.print(XBEE_DELAY_BETWEEN_SUBROUTINE_RETRY / 1000);
    USB.println(F("s ..."));
    #endif

    delay(XBEE_DELAY_BETWEEN_SUBROUTINE_RETRY);
    i--;

  }

  // Activation of XBee module failed
  if (i == 0) {

    #if USB_LOGS > 0
    USB.println(F(" > > XBee module failed to boot."));
    USB.println(F(" > > Rebooting Waspmote ..."));
    #endif

    PWR.reboot();

  }

  // XBee module activated
  else if (i > 0) {

    #if USB_LOGS > 0
    USB.println(F(" > > XBee module booted."));
    #endif

  }

  // 3G

  // Activation with retries of 3G module

  _3G.set_APN(_3G_APN_NAME);

  #if USB_LOGS > 0
  USB.println(F(" > > APN set."));
  #endif

  // Try multiples times to boot 3G module
  #if USB_LOGS > 0
  USB.println(F(" > > Booting 3G module ..."));
  #endif

  i = _3G_MAX_SUBROUTINE_TRY;
  while (_3G.ON() != 1 && i > 0) {

    #if USB_LOGS > 0
    USB.print(F(" > > > Error. Retry in "));
    USB.print(_3G_DELAY_BETWEEN_SUBROUTINE_RETRY / 1000);
    USB.println(F("s ..."));
    #endif

    delay(_3G_DELAY_BETWEEN_SUBROUTINE_RETRY);
    i--;

  }

  if (i == 0) {

    #if USB_LOGS > 0
    USB.println(F(" > > 3G module failed to boot."));
    USB.println(F(" > > Rebooting Waspmote ..."));
    #endif

    PWR.reboot();

  }

  else if (i > 0) {

    #if USB_LOGS > 0
    USB.println(F(" > > 3G module booted."));
    #endif

  }

  // Try multiples times to log in to 3G network
  #if USB_LOGS > 0
  USB.println(F(" > > Setting SIM PIN ..."));
  #endif

  i = _3G_MAX_SUBROUTINE_TRY;
  while (_3G.setPIN(_3G_SIM_PIN) != 1 && i > 0) {

    #if USB_LOGS > 0
    USB.print(F(" > > > Error. Retry in "));
    USB.print(_3G_DELAY_BETWEEN_SUBROUTINE_RETRY / 1000);
    USB.println(F("s ..."));
    #endif

    delay(_3G_DELAY_BETWEEN_SUBROUTINE_RETRY);
    i--;

  }

  if (i == 0) {

    #if USB_LOGS > 0
    USB.println(F(" > > SIM PIN setting failed."));
    USB.println(F(" > > Rebooting Waspmote ..."));
    #endif

    PWR.reboot();

  }

  else if (i > 0) {

    #if USB_LOGS > 0
    USB.println(F(" > > SIM PIN set."));
    #endif

  }

  // Check multiples times if connection is established
  #if USB_LOGS > 0
  USB.println(F(" > > Checking network ..."));
  #endif

  i = _3G_MAX_SUBROUTINE_TRY;
  while (_3G.check(60) != 1 && i > 0) {

    #if USB_LOGS > 0
    USB.print(F(" > > > Error. Retry in "));
    USB.print(_3G_DELAY_BETWEEN_SUBROUTINE_RETRY / 1000);
    USB.println(F("s ..."));
    #endif

    delay(_3G_DELAY_BETWEEN_SUBROUTINE_RETRY);
    i--;

  }

  if (i == 0) {

    #if USB_LOGS > 0
    USB.println(F(" > > Network checking failed."));
    USB.println(F(" > > Rebooting Waspmote ..."));
    #endif

    PWR.reboot();

  }

  else if (i > 0) {

    #if USB_LOGS > 0
    USB.println(F(" > > Network checked."));
    #endif

  }

  // Setup a reboot 24 hours later for security on memory

  #if USB_LOGS > 0
  USB.println(F("Sleeping :"));
  USB.print(F(" > > Reboot set in "));
  USB.println(TIME_BEFORE_REBOOT);
  #endif

  RTC.setAlarm1(TIME_BEFORE_REBOOT, RTC_OFFSET, RTC_ALM1_MODE2);

  #if USB_LOGS > 0
  USB.println(F(" > Waspmote booted."));
  #endif

}

/* ----- Main Program ----- */

void loop() {

  /* ----- Listening Network ----- */

  #if USB_LOGS > 0
  USB.println(F("----- New loop -----"));
  USB.println(F("Listening network :"));
  #endif

  // Wait for incoming transmission
  #if USB_LOGS > 0
  USB.print(F(" > Listening for incoming transmission for "));
  USB.print(LISTENING_TIME / 1000);
  USB.println(F("s ..."));
  #endif

  answer = xbee802.receivePacketTimeout(LISTENING_TIME);

  // Format received packet
  if (answer == 0) {

    #if USB_LOGS > 0
    USB.println(F(" > Transmission received."));
    #endif

    delay(2000);

    confirmation = xbee802.send(xbee802._srcMAC, "ok");

    if (confirmation == 0) {

      #if USB_LOGS > 0
      USB.println(F(" > Confirmation sent."));
      #endif

      /* ----- Formatting Data ----- */

      #if USB_LOGS > 0
      USB.println(F("Formatting data :"));
      #endif

      for (i = 0; i < xbee802._length; i++) {
        packet[i] = xbee802._payload[i];
      }

      #if USB_LOGS > 0
      USB.print(F(" > Packet received : "));
      USB.println(packet);
      #endif

      #if USB_LOGS > 1
      USB.print(F(" > Pre-uint8t_t*-to-char*-conversion packet : "));
      USB.println(xbee802._payload, xbee802._length);
      USB.print(F(" > Packet length : "));
      USB.println(xbee802._length, DEC);
      USB.print(F(" > Packet MAC source : "));
      for (i = 0; i < 8; i++) {
        USB.printHex(xbee802._srcMAC[i]);
      }
      USB.println();
      #endif

      subPacket = strtok(packet, "/");

      i = 0;
      while (subPacket != NULL) {
        strcpy(packetScratched[i], subPacket);
        subPacket = strtok(NULL, "/");
        i++;
      }

      sprintf(frame, "?id=%s&bat=%s&tmp=%s&lum=%s&hum=%s", packetScratched[0], packetScratched[1], packetScratched[2], packetScratched[3], packetScratched[4]);

      #if USB_LOGS > 0
      USB.print(F(" > Frame created : "));
      USB.println(frame);
      #endif

      /* ----- Sending Data ----- */

      #if USB_LOGS > 0
      USB.println(F("Sending data :"));
      #endif

      if (_3G.showsNetworkMode() > 1) {

        #if USB_LOGS > 0
        USB.println(F(" > 3G connection checked."));
        #endif

        char request[200];
        sprintf(request, "GET /reception%s HTTP/1.1\r\nHost: %s\r\nContent-Length: 0\r\n\r\n", frame, _3G_WEB_SERVER_IP);

        // Try multiples times to reach the URL
        #if USB_LOGS > 0
        USB.println(F(" > Reaching URL ..."));
        #endif

        i = _3G_MAX_SUBROUTINE_TRY;
        while (_3G.readURL(_3G_WEB_SERVER_IP, 80, request) != 1 && i > 0) {

          #if USB_LOGS > 0
          USB.print(F(" > > Error. Retry in "));
          USB.print(_3G_DELAY_BETWEEN_SUBROUTINE_RETRY / 1000);
          USB.println(F("s ..."));
          #endif

          delay(_3G_DELAY_BETWEEN_SUBROUTINE_RETRY);
          i--;

        }

        if (i == 0) {

          #if USB_LOGS > 0
          USB.println(F(" > Reaching URL failed."));
          USB.println(F(" > Rebooting Waspmote ..."));
          #endif

          PWR.reboot();

        }

        else if (i > 0) {

          #if USB_LOGS > 0
          USB.println(F(" > URL reached."));
          #endif

        }

      }

      else {

        #if USB_LOGS > 0
        USB.println(F(" > 3G connection can no longer be established."));
        USB.println(F(" > Rebooting Waspmote ..."));
          #endif

        PWR.reboot();

      }

    }

    else {

      #if USB_LOGS > 0
      USB.println(F(" > Confirmation not sent."));
      USB.println(F(" > Rebooting Waspmote..."));
      #endif

      PWR.reboot();

    }

  }

  // Received nothing
  else if (answer != 0) {

    #if USB_LOGS > 0
    USB.println(F(" > No transmission received or defective ones."));
    #endif

  }

  // Reboot after 24 hours
  if (intFlag & RTC_INT) {

    #if USB_LOGS > 0
    USB.println(F("Reboot :"));
    USB.println(F(" > An entire cycle has already occured."));
    USB.println(F(" > Rebooting Waspmote..."));
    #endif

    RTC.clearAlarmFlag();
    PWR.reboot();

  }

}
