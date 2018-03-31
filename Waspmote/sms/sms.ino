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
const char *text_message = "Connaisez-vous les lemuriens ?";
const char *pin_code = "1234";
const char *phone_number = "671763169";	// Only the 9 digits

void setup()
{
	// Setup for Serial port over USB:
	USB.ON();
	USB.println(F("USB port started..."));

	USB.printf("Going to send the following message to : %s\n\"%s\"\n", phone_number, text_message);

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
			answer = _3G.sendSMS(text_message, phone_number);
			if ( answer == 1) 
			{
				USB.println(F("SMS Sent OK")); 
			}
			else if (answer == 0)
			{
				USB.println(F("Error sending sms"));
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

