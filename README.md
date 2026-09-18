# fosdem

A Flutter project that displays the schedule of the FOSDEM agenda.

Every year in the beginning of februari there is a congres in Brussels,
organized by volunteers at the ULB (Université Libre Bruxelles)

This app is a complete rewrite of a previous app, that was written by Leo
Handreke and then enhanced by me to display the videos that came with the 
conferences, and some other stuff.

Apple removed it a year ago from their Appstore because they said it was stale, 
and the search did not work any more on their latest iterations of IOS. 

I decided to do a complete rewrite in Flutter, as I am more used to Flutter
nowadays that I ever was to Obj-C. The publication and useability of VLCkit via 
flutter_vlc_player made this possible.  At the moment vlc is not used, I am waiting for 
A Swift Package Manager version.

And as I am not interested anymore in products of a company that maximizes
profits instead of user satisfaction and useability, it was time to move on
and make something that could run on other platforms.

I mean, seriously, who in their right mind asks 400 US$ for a measly 16 GB extra 
memory and 200 US$ for an extra 512 GB SSD in a desktop machine in 2023, while SSD
NVME sticks of 1 TB can be bought for 100 US$?

I disgres. 

This app should make it a lot easier to enhance, add extra functionality etc. 
All the conference info is stored in a sqlite database.

Enjoy!



