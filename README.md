0) install vagrant from sysutils/vagrant (FreeBSD 11.1-RELEASE-p7)

1) search the vagrant boxes (https://app.vagrantup.com/boxes/search?provider=virtualbox)
https://app.vagrantup.com/boxes/search?provider=virtualbox

2) create image and start
	mkdir vagrant && cd vagrant
	vagrant init ubuntu/xenial64
	vagrant up (initial setup done automatically)
	
	vagrant ssh

3) install python and friends
	apt-get update
	apt-get install python python-pip
	; install pyowm
	pip  install pyowm

4) excercise 1 
	as required env variable is API_KEY,  getting one:
	http://openweathermap.org/appid
