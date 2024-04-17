# q-sys-plugin-kramer-protocol-3000

Q-SYS plugin for Kramer Protocol 3000

Language: Lua\
Platform: Q-Sys

Source code location: <https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000>

![Settings tab](https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000/blob/main/content/images/ui-tab-settings.png)\
![Matrix switcher tab](https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000/blob/main/content/images/ui-tab-matrix-switcher.png)\
![Utilities tab](https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000/blob/main/content/images/ui-tab-utilities.png)

## Demo project

A working demo Q-Sys Designer project is located at [//demo/Kramer Protocol 3000 - Demo.qsys](https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000/blob/main/demo/Kramer%20Protocol%203000%20-%20DEV.qsys)\
The demo project has all dependencies pre-loaded so it ready to load to use.

## Deploying code

### Dependencies

Install dependencies before installing the plugin.\
Dependencies (modules) are stored in the [//dependencies](https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000/blob/main/dependencies/) folder

Copy any/all module folders in the dependencies directly to the Q-Sys modules folder on your PC.\
For more detailed instructions on installing dependencies follow the instructions in the README located in the dependencies folder.

### The compiled plugin

The compiled plugin file is located in this repo at [//demo/q-sys-plugin-kramer-protocol-3000.qplug](https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000/blob/main/demo/q-sys-plugin-kramer-protocol-3000.qplug)\
Copy the *.qplug file into "**%USERPROFILE%\Documents\QSC\Q-Sys Designer\Plugins**" then drag the plugin into a design.

## Developing code

Instructions and resources for Q-Sys plugin development is available at:

* <https://q-syshelp.qsc.com/DeveloperHelp/>
* <https://github.com/q-sys-community/q-sys-plugin-guide/tree/master>

Do not edit the *.qplug file directly, this is created using the compiler.
"plugin.lua" contains the main code.

### Development and testing

The files in "//testing/" are for dev only and may not be the most current code, they were created from the main *.qplug file following these instructions for run-time debugging:\
[Debugging Run-time Code](https://q-syshelp.qsc.com/DeveloperHelp/#Getting_Started/Building_a_Plugin.htm?TocPath=Getting%2520Started%257C_____3)

### Protocol notes

The only way to accurately develop code for Kramer protocol 3000 is with live systems.\
Kramer protocol 3000 is a very loose protocol, Every Kramer device has it's own protocol manual that claims it uses Protocol 300 but the actual devices do not comply with the documented protocols.

## Features

### Features tested and functional

* Video matrix switching and feedback via crosspoint buttons and combo box selectors
* Output audio mute and feedback (Protocol doesn't support input audio mute)
* Output video disable and feedback (audio blank not supported)
* Output volume and feedback (note: not log scaled)
* Audio follow video
* Analog and Digital audio matrix switching including input and output embed and de-embed (buttons only visible when AFV is turned off).
* Displaying device information (SN, Version)
* Custom string insertion
* TCP and UDP control
  
### Features not tested

* Displaying device information (MAC, device name, model name)
* Input gain (not supported on VS-88 dev system)
* Serial control

### Features not implemented

* Authentication (protocol does not require authentication)
* HDCP enable and status
* Presets
* ARC
* EDID management

## References

* "samsungcommercialdisplay.qplug" by QSC
  * "Setup" page and socket management used as a template (e.g. TCP sockets and Serial comms).
* Original crosspoint logic referenced <https://github.com/jwetzell/q-sys-plugin-kramer-3000> by Joel Wetzell
  * Most original logic replaced, attribution remains here in case any references remains

## Contributors

Author: Rod Driscoll <rod@theavitgroup.com.au>
