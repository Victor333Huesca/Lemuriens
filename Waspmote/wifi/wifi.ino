#include <WaspUSB.h>
#include <WaspRTC.h>
#include <WaspPWR.h>
#include <WaspConstants.h>
#include <stdio.h>
#include <string.h>
#include <WaspWIFI.h>


// Declare globales object to bybass parsing bug, only used for Visual Studio Code.
#ifdef VSCODE
WaspUSB USB;
WaspRTC RTC;
WaspPWR PWR;
WaspWIFI WIFI;
#define F(str) str
void delay(int);
#endif



// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket = SOCKET0;
///////////////////////////////////////

// WiFi AP settings (CHANGE TO USER'S AP)
/////////////////////////////////
#define ESSID "RIP_le_Dragon"
#define AUTHKEY "RipLeMur"
/////////////////////////////////

void setup()
{
	// Switch ON the WiFi module on the desired socket
	if (WIFI.ON(socket) == 1)
	{
		USB.println(F("Wifi switched ON"));
	}
	else
	{
		USB.println(F("Wifi did not initialize correctly"));
	}

	// 1. Configure the transport protocol (UDP, TCP, FTP, HTTP...)
	WIFI.setConnectionOptions(CLIENT);
	// 2. Configure the way the modules will resolve the IP address.
	WIFI.setDHCPoptions(DHCP_ON);

	// *** Wifi Protected Access 2 (WPA 2) ***
	// 3. Sets WPA2-PSK encryptation // 1-64 Character
	WIFI.setAuthKey(WPA2, AUTHKEY);

	// 4. Configure how to connect the AP
	WIFI.setJoinMode(MANUAL);
	// 5. Store Values
	WIFI.storeData();
}

void loop()
{
	// Call join the AP
	if (WIFI.join(ESSID))
	{
		USB.println(F("joined AP"));

		// Displays Access Point status.
		USB.println(F("\n----------------------"));
		USB.println(F("AP Status:"));
		USB.println(F("----------------------"));
		WIFI.getAPstatus();

		// Displays IP settings.
		USB.println(F("\n----------------------"));
		USB.println(F("IP Settings:"));
		USB.println(F("----------------------"));
		WIFI.getIP();
		USB.println();

		// Call the function that needs a connection.
		WIFI.resolve("www.libelium.com");
	}
	else
	{
		USB.println(F("not joined"));
	}

	// Switch WiFi OFF
	WIFI.OFF();

	USB.println(F("************************"));

	// delay 2 seconds
	delay(2000);
}
