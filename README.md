# transparent_mitmproxy
script for running mitmproxy in transparent mode

Installing mitmproxy cert on android phone:
--------------------------

* open chrome
* go to: mitm.it
* click on the android logo to download cert
* If you receive a notification "failed to install cert"
* * go to Settings > Security > Install from storage
* * the cert should be under Downloads, click to install

Troubleshooting:
--------------------------

* The script should give you instructions on how to setup, if it still doesn't work; try the following
* make sure computer and phone are on same wifi network
* check that all ip addresses/ports/etc. are entered correctly in the phone's wifi settings
* tell the phone to forget the wifi connection and turn the phones wifi off and on 
* you’ll have to enter the advanced settings again
* * This happens frequently on android 7.0 or higher


For android 7.0 and higher 
--------------------------

* Only “System” certificates are trusted, so the certificate must be moved manually
* Connect phone to usb and enable developer settings/ debugging via usb
* The phone must first be rooted to perform the following commands
``adb shell ``
``su``
``cd /data/misc/user/0/cacerts-added``
``cp XXXXXXX.0 /system/etc/security/cacerts/`` (use filename of cert)
* if command fails, enter: ``mount –o rw,remount/system`` and try again
``chmod 644 /system/etc/security/cacerts/XXXXXXX.0``
``mount –o ro,remount /system`` (if necessary)
* restart the phone and go to settings > security > trusted credentials and make sure you see the certificate under system
