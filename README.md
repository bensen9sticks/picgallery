# picgallery
<b>A browser based picture gallery for all your pictures in your archive</b>

For years I am collecting my pictures in a simple folder structure where each folder represent one event or album. I was always looking for a tool to look at my pictures quickly on multiple devices, maybe being even able to take them with me without the hurdle to copy them every where or upload all of the to a cloud.

I developed a <b>perl script</b> that doesn't do much more than creating a web-page with my albums (the folder structure on my hard drive) that are search-able and selectable. Each album contains small thumbnails that are click able and open a nice full screen swipe interface to enjoy my pictures. It is designed to be fast and user friendly. The final result is easy to use in browsers, tables and phones.

The script in the "LibPicGallery folder" is written in perl and can be executed on any Linux system (I developed it on a OSX machine).

Simply clone this repository to your computer that has perl installed change into the "LibPicGallery" folder and execute the scrip in your shell by typing:

"perl picgallery.pm"

Before you do so you must do some minimal configuration in the header of the script. Simply open the scrip in your favourite editor and specify your source directory, where all your pictures are stored, and a target directory to generate the output.
You might want to specify your depth level depending on which folder depth you want to use for your album manes. This means if you store your picture first by year, in folders like 2019, 2020, 2021 and you generate sub folders in there with the "album" or "event" name, where finally the pictures are stored, you choose depth level "2". This is how the example gallery folder (ExampleGallerySource) is setup. If you don't use the years and just have all events in one folder (inside your source directory) you would use depth level "1".
The script doesn't touch your pictures it simply reads them and generates copies of smaller size to have your large XLR pictures optimized for web view.
Finally the specified target directory needs to be hosted by a web-server to make the generated web-page visible in your browser, tablet or phone.

This page is under construction and more details for install, usage and configuration will come in the following days (17.01.2021)
