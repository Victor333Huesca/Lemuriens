#include <WaspUSB.h>
#include <WaspRTC.h>
#include <WaspPWR.h>
#include <WaspConstants.h>
#include <Wasp3G.h>
#include <stdio.h>
#include <string.h>


// Declare globales object to bybass parsing bug, only used for Visual Studio Code.
#ifdef VSCODE
WaspUSB USB;
WaspRTC RTC;
WaspPWR PWR;
Wasp3G _3G;
#define F(str) str
#endif


int8_t answer;
const char *pin_code = "1234";
const char *sim_apn = "free";

const char *srv_url = "https://lemuriens.proj.info-ufr.univ-montp2.fr";
const char *srv_page = "index.php";
// const char *srv_url = "162.38.151.137";
// const char *srv_url = "http://localhost";
const uint16_t srv_port = 80;
const char *srv_data = "varA='Test_des_lemuriens'";

void setup()
{
	// Setup for Serial port over USB:
	USB.ON();
	USB.println(F("USB port started..."));

	USB.printf("Lets connect to %s to send the following text :\n\"%s\"\n", srv_url, srv_data);

	// 1. activates the 3G module:
	answer = _3G.ON();
	if ((answer == 1) || (answer == -3))
	{
		USB.println(F("3G module ready..."));

		// 2. sets pin code:
		USB.println(F("Setting PIN code..."));

		if (_3G.setPIN(pin_code) == 1) 
		{
			USB.println(F("PIN code accepted"));
		}
		else
		{
			USB.println(F("PIN code incorrect"));
		}

		// 3. waits for connection to the network
		answer = _3G.check(180);
		if (answer == 1)
		{ 
			USB.println(F("3G module connected to the network..."));

			_3G.set_APN((char *)sim_apn);

			// 4. sends an HTTP request
			answer = _3G.sendHTTPframe((const char*) srv_url, (uint16_t) srv_port, (uint8_t*) srv_data, (int) sizeof(srv_data), (uint8_t) POST, (uint8_t) 0);
			if ( answer == 1) 
			{
				USB.println(F("HTTP request successfuly sent"));
			}
			else if (answer == 0)
			{
				USB.println(F("No connection"));
			}
			else
			{
				USB.println(F("Error sending request")); 
				USB.print(F("CMS error code:")); 
				USB.println(answer, DEC);
				USB.print(F("CMS error code: "));
				USB.println(_3G.CME_CMS_code, DEC);
			}


			// 5. gets URL from the solicited URL
			USB.print(F("Getting URL with POST method..."));
			char tmp[256];
			sprintf(tmp, "POST %s HTTP/1.1\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n%s", srv_page, srv_url, strlen(srv_data), srv_data);

			answer = _3G.readURL("test.libelium.com", srv_port, tmp);
			if ( answer == 1) 
			{
				USB.println(F("HTTP request successfuly sent"));
			}
			else
			{
				USB.println(F("Error sending request")); 
				USB.print(F("CMS error code:")); 
				USB.println(answer, DEC);
				USB.print(F("CMS error code: "));
				USB.println(_3G.CME_CMS_code, DEC);
			}
		}
		else
		{
			USB.println(F("3G module cannot connect to the network..."));
		}
	}
	else
	{
		// Problem with the communication with the 3G module
		USB.println(F("3G module not started"));
	}    

	// 5. powers off the 3G module
	_3G.OFF();
}

void loop()
{

}

