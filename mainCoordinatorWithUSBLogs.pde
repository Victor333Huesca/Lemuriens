#include <WaspXBee802.h>
#include <Wasp3G.h>

/* ----- Configuration ----- */

// XBee Module
int MAX_XB_SUBROUTINE_TRY = 3;
int MAX_XB_TRIALS_BEFORE_REBOOT = 3;
char* TIME_BEFORE_NEW_XB_TRIALS = "00:00:00:10"; //1min

// 3G Module
char* APN_NAME = "free";
char* SIM_PIN = "1234";
int MAX_3G_SUBROUTINE_TRY = 3;
int MAX_3G_CONNECTION_TRY = 3;
int MAX_3G_TRIALS_BEFORE_REBOOT = 3;
char* TIME_BEFORE_NEW_3G_TRIALS = "00:00:00:10"; //2min

// Variables
int i, j, frameBufferCount = 0;
uint8_t answer;
char packet[100], frame[100], frameBuffer[6][100];
char* subPacket;
char packetScratched[5][10];
bool done;
char c[1];

bool connect3G() {

  // Already connected
  if (_3G.showsNetworkMode() > 1) {

    USB.println(F("Already connected in 3G."));

    return true;
  }


  _3G.set_APN(APN_NAME);

  // Try multiples times to boot 3G module

  USB.println(F("Booting 3G module..."));

  i = MAX_3G_SUBROUTINE_TRY;
  while (_3G.ON() != 1 && i > 0) {

    delay(3000);
    i--;

    USB.println(F("Retry... (3s)"));

  }

  if (i == 0) {

    USB.println(F("Booting failed."));

    return false;
  }

  else if (i > 0) {

    USB.println(F("Booted."));

  }

  // Try multiples times to log in to 3G network

  USB.println(F("Setting SIM PIN..."));

  i = MAX_3G_SUBROUTINE_TRY;
  while (_3G.setPIN(SIM_PIN) != 1 && i > 0) {

    delay(3000);
    i--;

    USB.println(F("Retry... (3s)"));

  }

  if (i == 0) {

    USB.println(F("Setting failed."));

    return false;
  }

  else if (i > 0) {

    USB.println(F("PIN set."));

  }

  // Check multiples times if connection is established

  USB.println(F("Checking 3G availability..."));

  i = MAX_3G_SUBROUTINE_TRY;
  while (_3G.check(180) != 1 && i > 0) {

    delay(3000);
    i--;

    USB.println(F("Retry... (3s)"));

  }

  if (i == 0) {

    USB.println(F("Checking failed."));

    return false;
  }

  else if (i > 0) {

    USB.println(F("Availability checked."));

  }

  return true;
}

bool send3GRequest(char* attributes) {

  char request[200];
  sprintf(request, "GET /reception%s HTTP/1.1\r\nHost: 31.35.122.165\r\nContent-Length: 0\r\n\r\n", attributes);

  // Try multiples times to reach the URL

  USB.println(F("Reading URL..."));

  i = MAX_3G_SUBROUTINE_TRY;
  while (_3G.readURL("31.35.122.165", 80, request) != 1 && i > 0) {

    delay(3000);
    i--;

    USB.println(F("Retry... (3s)"));

  }

  if (i == 0) {

    USB.println(F("Reading failed."));

    return false;
  }

  else if (i > 0) {

    USB.println(F("URL read."));

  }

  return true;
}

// At Waspmote boot
void setup() {

  USB.println(F("Booting Waspmote..."));

  RTC.ON(); // Needed for sleeping after failure to connect 3G

  // ZigBee

  // Activation with retries of XBee module

  USB.println(F("Booting XBee module..."));

  j = MAX_XB_TRIALS_BEFORE_REBOOT;
  do {

    USB.print(F("Trial "));
    USB.print(MAX_XB_TRIALS_BEFORE_REBOOT - j + 1);
    USB.print(F("/"));
    USB.println(MAX_XB_TRIALS_BEFORE_REBOOT);

    i = MAX_XB_SUBROUTINE_TRY;
    while (xbee802.ON() != 0 && i > 0) {

      delay(10000);
      i--;

      USB.println(F("Retry... (10s)"));

    }

    // If not connected, retry some time after
    if (i == 0) {

      USB.println(F("Trial failed."));
      USB.println(F("Sleeping."));
      USB.print(F("Wake up in "));
      USB.println(TIME_BEFORE_NEW_XB_TRIALS);

      PWR.deepSleep(TIME_BEFORE_NEW_XB_TRIALS, RTC_OFFSET, RTC_ALM1_MODE2, ALL_OFF);

      USB.println(F("Awake."));

      if (intFlag & RTC_INT) {

        RTC.clearAlarmFlag();

      }
    }

    j--;

  } while (i == 0 && j > 0);

  // Reboot if still not connected
  if (i == 0) {

    USB.println(F("XBee module failed to boot."));
    USB.println(F("Need to reboot Waspmote."));
    USB.println(F("Rebooting Waspmote..."));

    PWR.reboot();

  }

  // ZigBee-connected
  else if (i > 0) {

    USB.println(F("XBee module booted."));

  }

  // 3G

  // Activation with retries of 3G module

  USB.println(F("Setting up 3G module..."));

  j = MAX_3G_TRIALS_BEFORE_REBOOT;
  do {

    USB.print(F("Trial "));
    USB.print(MAX_3G_TRIALS_BEFORE_REBOOT - j + 1);
    USB.print(F("/"));
    USB.println(MAX_3G_TRIALS_BEFORE_REBOOT);

    // Boot and connect 3G
    i = MAX_3G_CONNECTION_TRY;
    while (!connect3G() && i > 0) {

      delay(3000);
      i--;

      USB.println(F("Retry... (3s)"));

    }

    // If not connected, retry some time after
    if (i == 0) {

      USB.println(F("Trial failed."));
      USB.println(F("Sleeping."));
      USB.print(F("Wake up in "));
      USB.println(TIME_BEFORE_NEW_3G_TRIALS);

      PWR.deepSleep(TIME_BEFORE_NEW_3G_TRIALS, RTC_OFFSET, RTC_ALM1_MODE2, ALL_OFF);

      USB.println(F("Awake."));

      if (intFlag & RTC_INT) {

        RTC.clearAlarmFlag();

      }
    }

    j--;

  } while (i == 0 && j > 0);

  // Reboot if still not connected
  if (i == 0) {

    USB.println(F("3G module failed to boot."));
    USB.println(F("Need to reboot Waspmote."));
    USB.println(F("Rebooting Waspmote..."));

    PWR.reboot();

  }

  // 3G-connected
  else if (i > 0) {

    USB.println(F("3G module booted."));

  }

  // Setup a reboot 24 hours later for security on memory

  USB.println(F("Setting up a reboot in 24h."));

  RTC.setAlarm1("23:59:00:00", RTC_OFFSET, RTC_ALM1_MODE2);

  USB.println(F("Waspmote booted."));

}

/* ----- Main Program ----- */

void loop() {

  USB.println(F("----- New loop -----"));

  // Wait for incoming transmission

  USB.println(F("Listening for incoming transmission... (5s)"));

  answer = xbee802.receivePacketTimeout(5000);

  // Format received packet
  if (answer == 0) {

    USB.println(F("Transmission incoming."));

    for (i = 0; i < xbee802._length; i++) {
      sprintf(c, "%d", xbee802._payload[i]);
      strcat(packet, c);
    }

    USB.print(F("uint8_t* packet received : "));
    USB.println(xbee802._payload, DEC);
    USB.print(F("char* packet : "));
    USB.println(packet);

    subPacket = strtok(packet, "/");

    i = 0;
    while (subPacket != NULL) {
      strcpy(packetScratched[i], subPacket);
      subPacket = strtok(NULL, "/");
      i++;
    }

    sprintf(frame, "?id=%s&?bat=%s&?tmp=%s&?lum=%s&?hum=%s", packetScratched[0], packetScratched[1], packetScratched[2], packetScratched[3], packetScratched[4]);

    USB.print(F("Frame to be sent : "));
    USB.println(frame);
    USB.print(F("Frames saved : "));
    USB.println(frameBufferCount);

    strcpy(frameBuffer[frameBufferCount], frame);
    frameBufferCount++;

  }

  // Received nothing
  else if (answer != 0) {

    USB.println(F("Heard nothing or defective transmission."));

  }

  // There is/are frame to be sent
  if (frameBufferCount > 0) {

    USB.println(F("Checking 3G connection..."));

    // Check if 3G connection is established
    i = MAX_3G_CONNECTION_TRY;
    while (!connect3G() && i > 0) {

      delay(3000);
      i--;

      USB.println(F("Retry... (3s)"));

    }

    // 3G connection can't be established but frame buffer isn't full : do nothing
    if (i == 0 && frameBufferCount < 6) {

      USB.println(F("3G not connected."));
      USB.println(F("Frame buffer isn't full (6)."));
      USB.println(F("Saving frame."));

    }

    // 3G connection can't be established and frame buffer is full : reboot and lose frames
    else if (i == 0 && frameBufferCount == 6) {

      USB.println(F("3G not connected."));
      USB.println(F("Frame buffer is full (6)."));
      USB.println(F("Need to reboot Waspmote."));
      USB.println(F("The frame in the buffer shall be lost."));
      USB.println(F("Rebooting Waspmote..."));

      PWR.reboot();

    }

    // 3G connection is established : empty the buffer
    else if (i > 0) {

      USB.println(F("3G connected."));
      USB.println(F("Emptying frame buffer..."));

      for (j = frameBufferCount; j > 0; j--) {

        USB.print(F("Sending frame : "));
        USB.print(frameBuffer[j]);
        USB.println(F("..."));

        done = send3GRequest(frameBuffer[j]);

        if (done) {

          USB.println(F("Frame sent."));

        }

        else {

          USB.println(F("Frame unsent."));

        }

        frameBufferCount--;

      }

      USB.println(F("Frame buffer emptied."));

    }
  }

  // Reboot after 24 hours
  if (intFlag & RTC_INT) {

    USB.println(F("An entire 24h cycle has already occured."));
    USB.println(F("Rebooting Waspmote..."));

    RTC.clearAlarmFlag();
    PWR.reboot();

  }

}
