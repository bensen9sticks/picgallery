<p align="center">
    <img height=120 src="https://github.com/bensen9sticks/picgallery/blob/main/LibPicGallery/picgallery_icon_top_g.png"><br/>
    A browser based picture gallery for all your pictures and videos in your archive
</p>

## Prerequisites
- [Perl](https://www.perl.org/) and some perl modules, [ImageMagick](https://imagemagick.org/), [FFmpeg](https://ffmpeg.org/) and any web server e.g. [nginx](https://www.nginx.com/)

## Install and Execution
- clone repo into your web directory
```
git clone https://github.com/bensen9sticks/picgallery/
```
- change config file to your needs (if you don't do anything the config file is setup to create the example gallery based on the example gallery folder, good for testing)
- execute perl script on the command line in LibPicGallery folder by: 
```
perl picgallery.pm picgallery.conf
```
- wait and than browse to the new .html file in the root directory

## Background of the Pic Gallery
For years I am collecting my pictures in a simple folder structure where each folder represent one event or album. I was always looking for a tool to look at my pictures quickly on multiple devices, maybe being even able to take them with me without the hurdle to copy them every where or upload all of them to a cloud.

I developed a <b>perl script</b> that doesn't do much more than creating a web-page with a list of my albums (the folder structure on my hard drive). The list elements (Albums) can be unfolded to present small thumbnail pictures that are click able and open a nice full screen swipe interface. Since over the years the albums go into the hundreds I added a google like search bar on the top of the page. The field searches as you type and allows to find your event quickly. It is designed to be fast and user friendly. The final result is easy to use in any browsers, tablet or phone.

## The Script
The script in the "LibPicGallery folder" is written in perl and can be executed on any Linux system (I developed it on a OSX machine).

Simply clone this repository to your computer that has perl installed change into the "LibPicGallery" folder and execute the scrip in your shell by typing:

```perl picgallery.pm```

Before you do so you must do some minimal configuration in the config file. Simply open the config file in your favorite editor and specify your source directory, where all your pictures are stored, and a target directory to generate the output. The latter would usually be in your web server directory.
You might want to specify your depth level depending on which folder depth you want to use for your album manes. This means if you store your picture first by year, in folders like 2019, 2020, 2021 and you generate sub folders in there with the "album" or "event" name, where finally the pictures are stored, you choose depth level "2". This is how the example gallery folder (ExampleGallerySource) is setup. If you don't use the years and just have all events in one folder (inside your source directory) you would use depth level "1".
The script doesn't touch your pictures it simply reads them and generates copies of smaller size to have your large XLR pictures optimized for web view.
Finally the specified target directory needs to be hosted by a web-server to make the generated web-page visible in your browser, tablet or phone.

## Example Gallery
I created an [example gallery](https://bensen9sticks.github.io/ExamplePicGallery.html) for all of you who would like to have a first look.

## License
picgallery is available under the [MIT license](https://opensource.org/licenses/MIT).
