# gateway_collection
Collection of config files and some glue logic scripts used for various gateways
I built. Each configuration is contained within its folder. Folder names are the
same as the hostname used for the machine.

## Kharon
From the greek mythology is the ferryman of Hades carrying the souls from the
world of the living to the world of the dead. It's the first gateway I built and
it ran on a raspberry Pi. Used a 3G modem and a WiFi USB key to act as an
access ponit. Some clever iptables magic allowed to track the amount of data
traffic used during the month.

## Lilith
Fairly complex one. It ran on an old laptop of mine. It was used to connect to
my dorm WiFi, bypass content filtering on the network to allow full internet
access and keep the connection active. The network required the user to enter
username and password and keep a tab open in the background. This tab had to be
refreshed periodically to keep the connection active. This refresh was done
automatically by a script within the page itself. Needless to say this method
sometimes did not work. Moreover on mobile phones when a tab is put in the
background it will be freezed. This access point solved the issue by faking a
user login and by simulating a page refresh once in a while.
There was also a web interface that allowed to check the status of the machine
and configure which websites were routed through a tunnel to avoid filtering.
Since this practice was not allowed within the network and can be considered
evil by some, this machine had the name of a daemon from the Jewish mythology.
Lilith is a dangerous daemon of the night that steals babies. The Talmud
describes her as the firs wife of Adam. She was exiled from the Garden of Eden
because she refused to submit and obey to Adam and coupled with the archangel
Samael.

There's some more detailed description which sadly is in italian. Open an issue
to let me know if you are interested in a translation or a pull request if you
happen to transalate it yourself.
