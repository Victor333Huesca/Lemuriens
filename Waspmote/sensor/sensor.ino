#include <WaspUSB.h>
#include <WaspRTC.h>
#include <WaspPWR.h>
#include <WaspConstants.h>
#include <WaspSensorEvent_v20.h>

// Declare globales object to bybass parsing bug, only used for Visual Studio Code.
#ifdef VSCODE
WaspUSB USB;
WaspRTC RTC;
WaspPWR PWR;
WaspSensorEvent_v20 SensorEventv20;
#endif


// THRESHOLD for interruption from the sensor

// Equivalent to 27ºC in this case
// GENERIC FORMULA: degrees(C) = ( volts - 0.5 ) * 100;
const float THRESHOLD_T = 0.77;

// GENERIC FORMULA: resistance(Lux) = 500 / ( (10000.0 * ( 5 - Vout ) ) / Vout ) ???
// GENERIC FORMULA: resistance(Lux)
const float THRESHOLD_L = 0.5;

// GENERIC FORMULA: humidity(% RH) = (volts * 100 / 3)
const float THRESHOLD_H = 1.5;

// Variable to store the temperature read value
float temperature, humidity, light;

/**
 * @brief Convert a float to a string.
 * 
 * @param flt number to convert.
 * @return const char* string \0 teminated representing the number.
 */
const char* ftoa(float flt) { static char float_buffer[10]; return dtostrf(flt, 1, 4, float_buffer); }

inline float voltToLux(float ohms) { float factor = 1e5f; return (1 / ohms) * factor; }		// Only works for linear LDR

void setup()
{
	// 1. Initialization of the modules

	// Turn on the USB and print a start message
	USB.ON();
	USB.println("start");

	// Turn on the sensor board
	SensorEventv20.ON();

	// Turn on the RTC
	RTC.ON();

	// Configure the socket 5 threshold
	SensorEventv20.setThreshold(SENS_SOCKET5, THRESHOLD_T);
	SensorEventv20.setThreshold(SENS_SOCKET6, THRESHOLD_H);
	SensorEventv20.setThreshold(SENS_SOCKET1, THRESHOLD_L);

	// Enable interruptions from the board
	SensorEventv20.attachInt();
}

void loop()
{
	///////////////////////////////////////
	// 1. Read the sensor voltage output
	///////////////////////////////////////

	// 1.1 Read the sensor voltage output
	temperature = SensorEventv20.readValue(SENS_SOCKET5);
	humidity = SensorEventv20.readValue(SENS_SOCKET6);
	light = SensorEventv20.readValue(SENS_SOCKET1);

	// Print the info
	USB.printf("Temperature output: %s Volts\n", ftoa(temperature));
	USB.printf("Humidity output: %s Volts\n", ftoa(humidity));
	USB.printf("Light output: %s Volts\n", ftoa(light));
	USB.println();


	// 1.2 Read the sensor output
	temperature = SensorEventv20.readValue(SENS_SOCKET5, SENS_TEMPERATURE);
	humidity = SensorEventv20.readValue(SENS_SOCKET6, SENS_HUMIDITY);
	light = SensorEventv20.readValue(SENS_SOCKET1, SENS_RESISTIVE);

	// Print the info
	USB.printf("Temperature output: %s Celsius\n", ftoa(temperature));
	USB.printf("Humidity output: %s %% RH\n", ftoa(humidity));
	USB.printf("Light output: %s Ohms\n", ftoa(light));
	USB.println();



	///////////////////////////////////////
	// 2. Go to deep sleep mode
	///////////////////////////////////////
	USB.println("...... Enter Deep Sleep (for ~10s) ......");
	PWR.deepSleep("00:00:00:10", RTC_OFFSET, RTC_ALM1_MODE1, SOCKET0_OFF);

	USB.ON();
	USB.println("...... Wake up Neo ......\n");



	///////////////////////////////////////
	// 3. Check Interruption Flags
	///////////////////////////////////////

	// 3.1. Check interruption from Sensor Board
	if (intFlag & SENS_INT)
	{
		// Was woke up by the sensor board (ie. one of the sensor has reached its threshold !)
		interrupt_function();
	}

	// 3.2. Check interruption from RTC alarm
	if (intFlag & RTC_INT)
	{
		// Was woke up by the RTC (should be the most common case)
		USB.println("-----------------------------");
		USB.println("RTC INT captured");
		USB.println("-----------------------------");

		// clear flag
		intFlag &= ~(RTC_INT);
	}

	USB.println();
}

/**********************************************
*
* interrupt_function()
*  
* Local function to treat the threshold interruption
*
*
***********************************************/
void interrupt_function()
{
	// Disable interruptions from the board
	SensorEventv20.detachInt();

	// Load the interruption flag
	SensorEventv20.loadInt();

	// Find the sensor that raise to interuption
	switch (SensorEventv20.intFlag) {
		case SENS_SOCKET5 :	// Temperature
			USB.println(" Interruption from socket 5  ");
			USB.println("-----------------------------");
			temperature = SensorEventv20.readValue(SENS_SOCKET5, SENS_TEMPERATURE);
			USB.printf("Temperature excess: %s Celsius\n", ftoa(temperature));
			break;

		case SENS_SOCKET6 : // Humidity
			USB.println("-----------------------------");
			USB.println(" Interruption from socket 6  ");
			USB.println("-----------------------------");
			humidity = SensorEventv20.readValue(SENS_SOCKET6, SENS_HUMIDITY);
			USB.printf("Humidity excess: %s %% RH\n", ftoa(humidity));
			break;

		case SENS_SOCKET1 : // LDR
			USB.println("-----------------------------");
			USB.println(" Interruption from socket 1  ");
			USB.println("-----------------------------");
			light = SensorEventv20.readValue(SENS_SOCKET1, SENS_RESISTIVE);
			USB.printf("Light excess: %s Ohms\n", ftoa(light));

			break;

		default : // Should never happend
			USB.println("-------------------------------");
			USB.println("Interruption from unkown socket");
			USB.println("-------------------------------");
			break;
	}

	// // In case the interruption came from socket 5 (ie. temperature)
	// if (SensorEventv20.intFlag & SENS_SOCKET5)
	// {
	// 	USB.println("-----------------------------");
	// 	USB.println(" Interruption from socket 5  ");
	// 	USB.println("-----------------------------");
	// }

	// // In case the interruption came from socket 6 (ie. humidity)
	// if (SensorEventv20.intFlag & SENS_SOCKET6)
	// {
	// 	USB.println("-----------------------------");
	// 	USB.println(" Interruption from socket 6  ");
	// 	USB.println("-----------------------------");
	// }

	// // In case the interruption came from socket 1 (ie. LDR)
	// if (SensorEventv20.intFlag & SENS_SOCKET1)
	// {
	// 	USB.println("-----------------------------");
	// 	USB.println(" Interruption from socket 1  ");
	// 	USB.println("-----------------------------");
	// }

	// Print the info
	// USB.printf("Temperature output: %s Celsius\n", temperature);
	// USB.printf("Humidity output: %s \% RH\n", humidity);
	// USB.printf("Light output: %s Ohms\n", light);
	// USB.println();

	// Clean the interruption flag
	intFlag &= ~(SENS_INT);

	// Enable interruptions from the board
	SensorEventv20.attachInt();
}
