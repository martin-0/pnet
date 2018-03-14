FROM python:2.7

WORKDIR /git/pnet/exercise1/docker

# add it to chroot
ADD ./getweather.py /git/pnet/exercise1/docker

RUN pip install pyowm

# request says though that env vars should be sources from the docker cmd
#ENV CITY_NAME Bratislava
#ENV OPENWEATHER_API_KEY xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
CMD ["python", "getweather.py"]

