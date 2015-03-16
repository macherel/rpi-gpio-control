import json
import urllib2
import base64
import sys
import RPi.GPIO as GPIO
import time
import os
import json
from pprint import pprint

config = {}

def readConf(filename):
	file = open(filename, 'r')
	config = json.load(file)
	file.close()
	return config

# Our function on what to do when the button is pressed
def onClick(channel):
	for action in config[str(channel)]:
		print action
		os.system(action)

config = readConf(sys.argv[1])

GPIO.setmode(GPIO.BOARD)
for pin in config.keys():
	print pin
	GPIO.setup(int(pin), GPIO.IN, pull_up_down = GPIO.PUD_UP)
	# Add our function to execute when the button pressed event happens
	GPIO.add_event_detect(int(pin), GPIO.FALLING, callback = onClick, bouncetime = 2000)

# Now wait!
while 1:
	time.sleep(1)
