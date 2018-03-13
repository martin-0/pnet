#!/usr/bin/env python2
#
# MI 2018
#

from pyowm import OWM
import os

def simple_sanity_check( var ):
	try:
		var.decode('ascii')
		return var
	except:
		print "[E] ascii check failed on variable '%s'"%var
		exit(2)


# check for required env variables
if ( (os.environ.get('OPENWEATHER_API_KEY') == None ) or (os.environ.get('CITY_NAME')) == None ):
	print "[E] env variables OPENWEATHER_API_KEY and CITY_NAME need to be defined, aborting.."
	exit(1)

# simple sanity check
city = simple_sanity_check(os.environ['CITY_NAME'])
wkey = simple_sanity_check(os.environ['OPENWEATHER_API_KEY'])

owm = OWM(wkey)

# observation & weather
try:
	obs = owm.weather_at_place(city)
except Exception as e:
	print "Failed to obtain data for %s: %s"%(city, str(e))
	exit(3)

w = obs.get_weather()

# XXX: I found no method to get the URL where the data is sourced from, using static string for the source
print '''source=openweathermap, city="%s", description="%s", temp=%s, humidity=%s'''%(obs.get_location().get_name(), w.get_detailed_status(),  w.get_temperature(unit='celsius')['temp'], w.get_humidity())

