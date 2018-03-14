0) install vagrant from sysutils/vagrant (FreeBSD 11.1-RELEASE-p7)

1) search the vagrant boxes (https://app.vagrantup.com/boxes/search?provider=virtualbox)
https://app.vagrantup.com/boxes/search?provider=virtualbox

2) create image and start
        $ mkdir vagrant && cd vagrant
        $ vagrant init ubuntu/xenial64
        $ vagrant up (initial setup done automatically)

        $ vagrant ssh   (using vagrant user)

        a) adding host-only interface

                $ grep "^[ ]*config.vm.network" Vagrantfile
                  config.vm.network "public_network", bridge: "vboxnet0", ip: XXXXXXXX

                $ vagrant validate
                $ vagrant reload

        b) add my pubkey to ~root/.ssh/authorized_keys so i can deploy other stuff more easily


3) install python and friends
        # apt-get update
        # apt-get install python python-pip
        # pip install pyowm

4) excercise 1
        as required env variable is API_KEY, getting one:
        http://openweathermap.org/appid


5) checked some docs on how to create a playbook:
        http://docs.ansible.com/ansible/latest/playbooks_intro.html#playbook-language-example
        http://docs.ansible.com/ansible/latest/apt_module.html

        deploy within the machine
        $ ansible-playbook -i "localhost," -c local /site.yml

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0


6) add vagrant user to docker group
        # usermod -G docker vagrant

7) setting the image
        $ docker run hello-world
        $ docker image ls

        a) create custom image - Dockerfile, build the image
        $ docker build -t weather .

        $ docker run weather
        source=openweathermap, city="Bratislava", description="clear sky", temp=9.56, humidity=57
        $

        b) configure the log driver
        https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver

	create the file file: /etc/docker/daemon.json 
	# grep openweathermap /var/log/syslog | tail -1
	Mar 14 10:25:29 ubuntu-xenial f939db3f9c3c[11300]: source=openweathermap, city="Bratislava", description="broken clouds", temp=8.44, humidity=61
	#

