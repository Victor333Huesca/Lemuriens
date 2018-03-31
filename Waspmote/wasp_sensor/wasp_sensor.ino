#include <WaspUSB.h>
#include <WaspRTC.h>
#include <WaspPWR.h>
#include <WaspConstants.h>
#include <WaspSensorEvent_v20.h>
#include <string.h>
#include <stdio.h>

// Declare globales object to bybass parsing bug, only used for Visual Studio Code.
#ifdef VSCODE
WaspUSB USB;
WaspRTC RTC;
WaspPWR PWR;
WaspSensorEvent_v20 SensorEventv20;
#endif

// const char* to_time(int seconds, int minutes = 0, int hours = 0, int days = 0);

// THRESHOLD for interruption from the sensor

// Equivalent to 27ºC in this case
// GENERIC FORMULA: degrees(C) = ( volts - 0.5 ) * 100;
const float THRESHOLD_T = 0.77;

// GENERIC FORMULA: resistance(Lux) = 500 / ( (10000.0 * ( 5 - Vout ) ) / Vout ) ???
// GENERIC FORMULA: resistance(Lux)
const float THRESHOLD_L = 0.5;

// GENERIC FORMULA: humidity(% RH) = (volts * 100 / 3)
const float THRESHOLD_H = 1.5;

// Variable to store the temperature, humidity and light
float temperature, humidity, light;

/**
 * @brief Convert a float to a string.
 * 
 * @param flt number to convert.
 * @return const char* string \0 teminated representing the number.
 */
const char* ftoa(float flt) { static char float_buffer[10]; return dtostrf(flt, 1, 4, float_buffer); }

/**
 * @brief Convert resistance from LDR to lux.
 * 
 * /!\ Only works for linear LDR.
 * 
 * @param ohms risistance in ohms.
 * @return float Luminosity in lux.
 */
inline float voltToLux(float ohms) { float factor = 1e5f; return (1 / ohms) * factor; }

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
	if (SensorEventv20.intFlag & ) {
		if (SensorEventv20.intFlag & SENS_SOCKET5) {	// Temperature
			USB.println(" Interruption from socket 5  ");
			USB.println("-----------------------------");
			temperature = SensorEventv20.readValue(SENS_SOCKET5, SENS_TEMPERATURE);
			USB.printf("Temperature excess: %s Celsius\n", ftoa(temperature));
			}

		if (SensorEventv20.intFlag & SENS_SOCKET6) { // Humidity
			USB.println("-----------------------------");
			USB.println(" Interruption from socket 6  ");
			USB.println("-----------------------------");
			humidity = SensorEventv20.readValue(SENS_SOCKET6, SENS_HUMIDITY);
			USB.printf("Humidity excess: %s %% RH\n", ftoa(humidity));
			}

		if (SensorEventv20.intFlag & SENS_SOCKET1) { // LDR
			USB.println("-----------------------------");
			USB.println(" Interruption from socket 1  ");
			USB.println("-----------------------------");
			light = SensorEventv20.readValue(SENS_SOCKET1, SENS_RESISTIVE);
			USB.printf("Light excess: %s Ohms\n", ftoa(light));
			}

		else {} // Should never happend
			USB.println("-------------------------------");
			USB.println("Interruption from unkown socket");
			USB.println("-------------------------------");
            temperature = SensorEventv20.readValue(SENS_SOCKET5, SENS_TEMPERATURE);
			humidity = SensorEventv20.readValue(SENS_SOCKET6, SENS_HUMIDITY);
			light = SensorEventv20.readValue(SENS_SOCKET1, SENS_RESISTIVE);
            USB.printf("Temperature : %s Celsius\n", ftoa(temperature));
			USB.printf("Humidity : %s %% RH\n", ftoa(humidity));
			USB.printf("Light : %s Ohms\n", ftoa(light));
			}
	}

	// Clean the interruption flag
	intFlag &= ~(SENS_INT);

	// Enable interruptions from the board
	SensorEventv20.attachInt();
}


// const char* to_time(int seconds, int minutes = 0, int hours = 0, int days = 0)
// {
//     static char buf[] = "00:00:00:00";
//     sprintf(buf, "%2d:%2d:%2d:%2d", days, hours, minutes, seconds);

//     return buf;
// }