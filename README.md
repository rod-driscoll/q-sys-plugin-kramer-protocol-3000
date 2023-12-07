# q-sys-plugin-kramer-protocol-3000

Q-SYS plugin for Kramer Protocol 3000

Language: Lua\
Platform: Q-Sys

Source code location: <https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000>

![Settings tab](https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000/blob/main/content/images/ui-tab-settings.png)\
![Matrix switcher tab](https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000/blob/main/content/images/ui-tab-matrix-switcher.png)

## Deploying code

Instructions and resources for Q-Sys plugin development is available at:

* <https://q-syshelp.qsc.com/DeveloperHelp/>
* <https://github.com/q-sys-community/q-sys-plugin-guide/tree/master>

Do not edit the *.qplug file directly, this is created using the compiler.
"plugin.lua" contains the main code.

### Development and testing

The files in "./DEV/" are for dev only and may not be the most current code, they were created from the main *.qplug file following these instructions for run-time debugging:\
[Debugging Run-time Code](https://q-syshelp.qsc.com/DeveloperHelp/#Getting_Started/Building_a_Plugin.htm?TocPath=Getting%2520Started%257C_____3)

## Features

### Features tested and functional

* Video matrix switching
* Output audio mute (Protocol doesn't support input audio mute)
* Output video disable (audio blank not supported)
* Displaying device information (MAC, SN, FW, Hostname)
  
### Features not tested

* Input and output gain (not supported on VS-88 dev system)
* Serial control

### Features not implemented

* Authentication (protocol does not require authentication)
* HDCP enable and status
* Audio embed

## References

* "samsungcommercialdisplay.qplug" by QSC
  * "Setup" page and socket management used as a template (e.g. TCP sockets and Serial comms).
* Original crosspoint logic referenced <https://github.com/jwetzell/q-sys-plugin-kramer-3000> by Joel Wetzell
  * Most original logic replaced, attribution remains here in case any references remains

## Contributors

Author: Rod Driscoll <rod@theavitgroup.com.au>
