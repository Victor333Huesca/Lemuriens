#include <WaspUSB.h>
#include <WaspRTC.h>
#include <WaspPWR.h>
#include <WaspConstants.h>
#include <Wasp3G.h>


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

const char *srv_url = "https://lemuriens.proj.info-ufr.univ-montp2.fr/";
const uint16_t srv_port = 80;
const uint8_t *srv_data = "varA=1";

void setup()
{
	// Setup for Serial port over USB:
	USB.ON();
	USB.println(F("USB port started..."));

	// 1. activates the 3G module:
	answer = _3G.ON();
	if ((answer == 1) || (answer == -3))
	{
		USB.println(F("3G module ready..."));

		// 2. sets pin code:
		USB.println(F("Setting PIN code..."));
		// **** must be substituted by the SIM code
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
			// 4. sends an SMS
			if (_3G.setTextModeSMS())
			{
				// Success
				USB.println(F("SMS mode successfully set up"));
			}
			else
			{
				// Error
				USB.println(F("Error setting SMS mode"));
			}

			answer = _3G.sendHTTPframe(srv_url, srv_port, srv_data, (int)sizeof(srv_data), (uint8_t)POST);
			if ( answer == 1) 
			{
				USB.println(F("SMS Sent OK"));
				
			}
			else if (answer == 0)
			{
				USB.println(F("No connection"));
			}
			else
			{
				USB.println(F("Error sending sms")); 
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

