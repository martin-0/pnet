[![N|Solid](https://cldup.com/dTxpPi9lDf.thumb.png)](https://nodesource.com/products/nsolid)
## Excercises
### 0) Host setup

I've FreeBSD 11.1-RELEASE-p7 running VirtualBox - this will be the host machine. 
  - Install vagrant from sysutils/vagrant
  - search the available vagrant boxes [app.vagrantup.com][vg1] 
  - create image and start the box
```sh
host(~)$ mkdir vagrant && cd vagrant
host(~)$ vagrant init ubuntu/xenial64
host(~)$ vagrant up
host(~)$ vagrant ssh
````
I'd like to use host-only interface too:
```sh
host(~)$ grep "^[ ]*config.vm.network" Vagrantfile
    config.vm.network "public_network", bridge: "vboxnet0", ip: XXXXXXXX
host(~)$ vagrant validate
host(~)$ vagrant reload
```
  - add my pub keys to root/vagrant users

I'll refer to the spawned VM as node01. First I need to install python and required module for ex#1. 
```sh
node01(~)# apt-get update
node01(~)# apt-get install python python-pip
node01(~)# pip install pyowm
```

### 1) Excercise #1
This excercise has following objectives:
- create script that fetches current weather from a given city
- install docker using ansible
- change default logging device to syslog
- run the script inside docker and log the result back to syslog

To use the weather API I need to have the API key. I can obtain one from [openweatehrmap][ow1]. I've created the script [getweather.py][gwpy] and tested it works as expected. 

I had to go through the docs on how to create such playbook, went through [generic examples][pb1] and [apt module][pb2] docs. I've created the [playbook file][pb3]. I used it to install docker. Then I had to add my current user to the proper docker group. 
```sh
node01(~)$ ansible-playbook -i "localhost," -c local /site.yml
<<output omitted>>
PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0
node01(~)$ su
node01(~)# usermod -G docker vagrant
```
Now I'm ready to create required docker container. I've created the [docker file][df1], set the [/etc/docker/daemon.json][df2] as shown in [docker logging driver][dl1] docs and restarted the docker service. 

```sh
node01(~)# systemctl restart docker.service
node01(~)$ docker image ls
node01(~)$ docker build -t weather .
```
Test the solution:
```sh
node01(~)$ docker run --rm -e CITY_NAME=Bratislava -e OPENWEATHER_API_KEY=xxxxxxxxx weather
    source=openweathermap, city="Bratislava", description="broken clouds", temp=8.88, humidity=57
node01(~)$ su
node01(~)# grep openweathermap /var/log/syslog |tail -1
Mar 14 11:32:47 ubuntu-xenial c57db3274f55[11300]: source=openweathermap, city="Bratislava", description="broken clouds", temp=8.88, humidity=57
```
### 2) Excercise #2
TODO

### 3) Excercise #3
I've created new Vagrant file to have two nodes - node01/node02, fresh setup. Objectives are:
- do the whole setup using ansible and roles
- make it possible for ansible to accept additional parameters to configure:
    - remote syslog server
    - additional custom log files

Using the [playbook][pb4] I did the setup as instructed. The role "syslog-rs" is setting node01 to be listening on port 514 TDP/UDP, just to have some listening syslog service. Clients can use any syslog server using "rsyslog_server" parameter. 

Test scenario1 : remote server node01, 3 custom programs:
```sh
host(~)$ ansible-playbook -i hosts -e rsyslog_server=node01 -e '{cprogs:[prog1,prog2,prog3]}' playbook.yml
```
System status after deployment: 
```sh
node01(~)# ll /etc/rsyslog.d/
total 16
drwxr-xr-x  2 root root 4096 Mar 14 23:30 ./
drwxr-xr-x 96 root root 4096 Mar 14 18:03 ../
-rw-r-----  1 root root  720 Mar 14 23:30 50-default.conf
-rw-r--r--  1 root root  186 Mar 14 23:30 99-custom.conf
node01(~)# grep "@" /etc/rsyslog.d/50-default.conf
node01(~)# cat /etc/rsyslog.d/99-custom.conf
if $programname == "prog1" then /var/log/custom/prog1.log
& ~
if $programname == "prog2" then /var/log/custom/prog2.log
& ~
if $programname == "prog3" then /var/log/custom/prog3.log
& ~
node01(~)#

node02(~)# grep "@" /etc/rsyslog.d/50-default.conf
*.*     @node01
node02(~)#
```
Using my test program I've sent message to syslog on node02, message was sent to remote syslog on node01 too:
```sh
node02(~)# ./prog1
node02(~)# cat /var/log/custom/prog1.log
Mar 14 23:33:43 node02 prog1: hello syslog from 29537
node02(~)#

node01(~)# cat /var/log/custom/prog1.log
Mar 14 23:33:43 node02 prog1: hello syslog from 29537
node01(~)#
```

Test scenario 2: no remote syslog, no custom logs:
```sh
ansible-playbook -i hosts playbook.yml
```

Now we don't have any remote syslog servers configured in syslog, there are no additional config files in rsyslog.d either:
```sh
node01(~)# ll /etc/rsyslog.d/
total 12
drwxr-xr-x  2 root root 4096 Mar 14 23:38 ./
drwxr-xr-x 96 root root 4096 Mar 14 18:03 ../
-rw-r-----  1 root root  720 Mar 14 23:38 50-default.conf
node01(~)# grep "@" /etc/rsyslog.d/50-default.conf
node01(~)#

node02(~)# ll /etc/rsyslog.d/
total 12
drwxr-xr-x  2 root root 4096 Mar 14 23:38 ./
drwxr-xr-x 96 root root 4096 Mar 14 22:48 ../
-rw-r-----  1 root root  720 Mar 14 23:38 50-default.conf
node02(~)#  grep "@" /etc/rsyslog.d/50-default.conf
node02(~)#
```

NOTE: /var/log/custom/* directory was not removed though as there's no way of telling what else was there before, or if it's actually desired to remove these logs. If yes, it would be possible to remove it the same way as /etc/rsyslog.d/*.conf files were removed. 

[vg1]: https://app.vagrantup.com/boxes/search?provider=virtualbox
[ow1]: http://openweathermap.org/appid
[gwpy]:https://github.com/martin-0/pnet/blob/master/exercise1/getweather.py
[pb1]: http://docs.ansible.com/ansible/latest/playbooks_intro.html#playbook-language-example
[pb2]: http://docs.ansible.com/ansible/latest/apt_module.html
[pb3]: https://github.com/martin-0/pnet/blob/master/exercise1/site.yml
[df1]: https://github.com/martin-0/pnet/blob/master/exercise1/Dockerfile
[df2]: https://github.com/martin-0/pnet/blob/master/exercise1/daemon.json
[dl1]: https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver
[pb4]: https://github.com/martin-0/pnet/blob/master/exercise3/playbook.yml

