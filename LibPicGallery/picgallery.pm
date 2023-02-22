#!/usr/bin/perl

###############################################################################
#
# Developed for Steffi
#
#  PiGallery perl script by Benjamin Neunstoecklin under MIT licence
#
#  Special thanks goes to:
#       - Steffi
#       - Dmitry Semenov for the PhotoSwipe functionallity
#
#  Copyright (c) 2020-2021 Benjamin Neunstoecklin (b dot neunstoecklin at gmail dot com)
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in all
#  copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.
#
#
#  GITHUB Homepage: https://github.com/bensen9sticks/picgallery
#
#  picgallery.pm 2023-01-06 bensen9
#
###############################################################################


my $configFileName = $ARGV[0];
my %configParamHash = ();
open ( CONF, $configFileName ) or die "Unable to open config file: $!";
while ( <CONF> ) {
    chomp;
    s/#.*//;                # ignore comments
    s/^\s+//;               # trim leading spaces if any
    s/\s+$//;               # trim leading spaces if any
    next unless length;
    my ($_configParam, $_paramValue) = split(/\s*=\s*/, $_, 2);
    $configParamHash{$_configParam} = $_paramValue;
}
close CONF;

print "\n--- Your configuration looks as follows ---\n";
while ( ($k,$v) = each %configParamHash ) {
    print "$k => $v\n";
}
print "--- End of configuration ---\n\n";

my $source_folder1    = $configParamHash{source_folder1};
my $albumdepthlevel1  = $configParamHash{albumdepthlevel1};
my $source_folder2    = $configParamHash{source_folder2};
my $albumdepthlevel2  = $configParamHash{albumdepthlevel2};
my $target_folder     = $configParamHash{target_folder};
my $gallery_name_long = $configParamHash{gallery_name_long};
my $googleapikey      = $configParamHash{googleapikey};
my $uicolor           = $configParamHash{uicolor};

my $fhemreporting     = $configParamHash{fhemreporting};
my $fhemplpath        = $configParamHash{fhemplpath};
my $fhemtelnetport    = $configParamHash{fhemtelnetport};
my $fhemdummyname     = $configParamHash{fhemdummyname};

my $album_processing_only = "no";
if ( $ARGV[1] eq "albumonly" ) { $album_processing_only = "yes"; }

# ------------------------------------------------------------------------------ #
# --- Start of scrip here, don't change if you don't know what you are doing --- #
# ------------------------------------------------------------------------------ #
use 5.010;
use File::Find;
use Image::ExifTool ':Public';
# ImageMagick and ffmpeg need to be installed on your system.
# use Image::Scale;
# use strict;
# use warnings;

$"= "\n";
my $startofscript = localtime();
my $gallery_name = $gallery_name_long;
   $gallery_name =~ s/[^0-9a-zA-Z]//g; # remove everything but numbers and letters from the gallery name
if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setstate $fhemdummyname running; setreading $fhemdummyname script_status running\""; }

# Development and debug variables
# system "rm -r /Users/iSleepy/Sites/picgal/PicGalleryBen/20200628LagotestAlbu/"; # delete my test target folder to test changes. Comment this line out during normal operation

# Make main directory on server for albums and album html files
mkdir ("$target_folder/$gallery_name");

# Get album names from source folder 1 names based on depth level 1 and sort Z to A
my $startingfolderdepth1 = $source_folder1 =~ tr[/][];
my $totalfolderdepth1 = $startingfolderdepth1 + $albumdepthlevel1;
find ( { preprocess => \&PreProcess1, wanted => \&Wanted1, }, $source_folder1);
sub PreProcess1 { my $currentdepth = $File::Find::dir =~ tr[/][]; return grep { -d} @_ if $currentdepth < $totalfolderdepth1; }
sub Wanted1     { if ( ($File::Find::name =~ tr[/][]) == $totalfolderdepth1 && $File::Find::name !~ m/\.photos?library/i && $File::Find::name !~ m/synchronisieren/i ) {
    push @dirs1, $File::Find::name if -d; }
}
@dirs1 = sort { $b cmp $a } @dirs1; # Z to A sorted directory list based on $albumdepthlevel
print "\nDIRS1\n@dirs1\n\n";

# Get album names from source folder 2 names based on depth level 2 and sort Z to A
my $startingfolderdepth2 = $source_folder2 =~ tr[/][];
my $totalfolderdepth2 = $startingfolderdepth2 + $albumdepthlevel2;
find ( { preprocess => \&PreProcess2, wanted => \&Wanted2, }, $source_folder2);
sub PreProcess2 { my $currentdepth = $File::Find::dir =~ tr[/][]; return grep { -d} @_ if $currentdepth < $totalfolderdepth2; }
sub Wanted2     { if ( ($File::Find::name =~ tr[/][]) == $totalfolderdepth2 && $File::Find::name !~ m/\.photos?library/i && $File::Find::name !~ m/synchronisieren/i ) {
    push @dirs2, $File::Find::name if -d; }
}
@dirs2 = sort { $b cmp $a } @dirs2; # Z to A sorted directory list based on $albumdepthlevel
print "\nDIRS2\n@dirs2\n\n";

my @dirs = (@dirs2, @dirs1);

print "\n---   Full path of all albums in source directories   ---\n@dirs\n\n";
if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setreading $fhemdummyname album 0 ; setreading $fhemdummyname album_last " . scalar @dirs . "\""; }

# --- Generate start of main html of Gallery in server root directory --- #
open  (H, "> $target_folder/$gallery_name.html");
print  H <<XML;
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="description" content="A picture gallery for all pictures in my archive">
  <meta name="keywords" content="HTML, CSS, JavaScript, PicGallery, Picture, Gallery, Picture Gallery">
  <meta name="author" content="Ben Neunstoecklin">
  <meta name="viewport" content = "width=device-width, initial-scale=0.5, user-scalable=no, viewport-fit=cover" />
  <meta name="apple-mobile-web-app-title" content="$gallery_name" />
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default" />
XML
if ($uicolor eq "girl") {
  print H "  <link rel=\"apple-touch-icon\" href=\"./LibPicGallery/iOSicon-gallery_g.png\">\n";
  print H "  <link rel=\"shortcut icon\"    href=\"./LibPicGallery/iOSicon-gallery_g.png\">\n";
}
else {
  print H "  <link rel=\"apple-touch-icon\" href=\"./LibPicGallery/iOSicon-gallery_b.png\">\n";
  print H "  <link rel=\"shortcut icon\"    href=\"./LibPicGallery/iOSicon-gallery_b.png\">\n";
}
print  H <<XML;
  <link rel="stylesheet" href="./LibPicGallery/picgallery.css">
  <link rel="stylesheet" href="./LibPicGallery/photoswipe.css">
  <link rel="stylesheet" href="./LibPicGallery/photoswipe-skin/default-skin.css">
  <script src="./LibPicGallery/photoswipe.min.js"></script>
  <script src="./LibPicGallery/photoswipe-ui-default.min.js"></script>

  <title>$gallery_name</title>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
  <script>
    \$(document).ready(function(){
        \$("a").one("click",function(){
            \$(this.nextElementSibling).load(\$(this).attr("filetoload"));
        });
    });
  </script>
  <script>
  function SearchField() {
      var input, filter, list, line, a, i, txtValue;
      input = document.getElementById("myInput");
      filter = input.value.toUpperCase();
      filter = filter.replace(/\\s/gi, ".*");
      list = document.getElementById("myUL");
      line = list.getElementsByClassName("lineitem");
      for (i = 0; i < line.length; i++) {
          a = line[i].getElementsByTagName("a")[0];
          txtValue = a.textContent || a.innerText;
          txtValue = txtValue.replace(/\\s/gi, "");
          txtValue = txtValue.replace(/-/gi, "");
          txtValue = txtValue.replace(/_/gi, "");
          if (txtValue.toUpperCase().match(filter) != null) {
              line[i].style.display = "";
          } else {
              line[i].style.display = "none";
          }
      }
  }
  </script>
  <script>
  function ToggleOffPics() {
    var pics = document.getElementsByClassName("pic");
    var i;
    for (i = 0; i < pics.length; i++) {
      if (pics[i].style.display !== "none") {
        pics[i].style.display = "none";
        if ( i == 0 ) {
          document.getElementById("TogOffPic").getElementsByTagName("img")[0].src = "./LibPicGallery/picgallery_fct_pic-off.png";
          document.getElementById("TogOffPic").getElementsByTagName("div")[0].innerHTML = "Pic Off";
        }
      } else {
        pics[i].style.display = "";
        if ( i == 0 ) {
          document.getElementById("TogOffPic").getElementsByTagName("img")[0].src = "./LibPicGallery/picgallery_fct_pic-on.png";
          document.getElementById("TogOffPic").getElementsByTagName("div")[0].innerHTML = "Pic On";
        }
      }
    }
  }
  </script>
  <script>
  window.onload= function (){
      var coll = document.getElementsByClassName("collapsible");
      var i;
      for (i = 0; i < coll.length; i++) {
        coll[i].addEventListener("click", function() {
          this.classList.toggle("active");
          var content = this.nextElementSibling;
          if (content.style.display === "flex") {
            content.style.display = "none";
          } else {
            content.style.display = "flex";
          }
        });
      }
  }
  </script>
</head>
XML
if ($uicolor eq "girl") { print H "<body style=\"background-color: #FF0090;\">\n";}
else                    { print H "<body>\n";}
print  H <<XML;
 <!-- Root element of PhotoSwipe. Must have class pswp. -->
 <div class="pswp" tabindex="-1" role="dialog" aria-hidden="true">
     <!-- Background of PhotoSwipe. It's a separate element, as animating opacity is faster than rgba(). -->
     <div class="pswp__bg"></div>
     <!-- Slides wrapper with overflow:hidden. -->
     <div class="pswp__scroll-wrap">
         <!-- Container that holds slides. PhotoSwipe keeps only 3 slides in DOM to save memory. -->
         <!-- don't modify these 3 pswp__item elements, data is added later on. -->
         <div class="pswp__container">
             <div class="pswp__item"></div>
             <div class="pswp__item"></div>
             <div class="pswp__item"></div>
         </div>
         <!-- Default (PhotoSwipeUI_Default) interface on top of sliding area. Can be changed. -->
         <div class="pswp__ui pswp__ui--hidden">
             <div class="pswp__top-bar">
                 <!--  Controls are self-explanatory. Order can be changed. -->
                 <div class="pswp__counter"></div>
                 <button class="pswp__button pswp__button--close" title="Close (Esc)"></button>
                 <button class="pswp__button pswp__button--share" title="Share"></button>
                 <button class="pswp__button pswp__button--fs" title="Toggle fullscreen"></button>
                 <button class="pswp__button pswp__button--zoom" title="Zoom in/out"></button>
                 <!-- Preloader demo https://codepen.io/dimsemenov/pen/yyBWoR -->
                 <!-- element will get class pswp__preloader active when preloader is running -->
                 <div class="pswp__preloader">
                     <div class="pswp__preloader__icn">
                       <div class="pswp__preloader__cut">
                         <div class="pswp__preloader__donut"></div>
                       </div>
                     </div>
                 </div>
             </div>
             <div class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap">
                 <div class="pswp__share-tooltip"></div>
             </div>
             <button class="pswp__button pswp__button--arrow--left" title="Previous (arrow left)"></button>
             <button class="pswp__button pswp__button--arrow--right" title="Next (arrow right)"></button>
             <div class="pswp__caption">
                 <div class="pswp__caption__center"></div>
             </div>
           </div>
         </div>
 </div>

 <pagehead>
XML
if ($uicolor eq "girl") { print H "   <img src=\"./LibPicGallery/picgallery_icon_top_g.png\" itemprop=\"thumbnail\" alt=\"Img\" />\n"; }
else                    { print H "   <img src=\"./LibPicGallery/picgallery_icon_top_b.png\" itemprop=\"thumbnail\" alt=\"Img\" />\n"; }
print  H <<XML;
   <div>$gallery_name_long
       <div id="TogOffPic" class="fctbut" type="button" onClick="ToggleOffPics()">
         <img src="./LibPicGallery/picgallery_fct_pic-on.png" itemprop="thumbnail" alt="Img"><div>Pic On</div>
       </div>
       <div id="Reload"    class="fctbut" type="button" onClick="window.location.reload(true)">
         <img src="./LibPicGallery/picgallery_fct_reload.png" itemprop="thumbnail" alt="Img"><div>Reload</div>
       </div>
   </div>
 </pagehead>

 <div class="inputback"><input type="text" id="myInput" onkeyup="SearchField()" placeholder="Search for events or album names..." title="Type in a name"></div>

 <div class="listbackg">
 <list id="myUL">
  <div class="lineitem"><a type="button" class="collapsible google" filetoload=\"./$gallery_name/GPS.html\">Pins on Google Maps <span class="small">(for pictures with GPS information only)</span></a><div></div></div>
XML
close (H);

# --- Generate start of overall GPS html file --- #
open  (GPS, "> $target_folder/$gallery_name/GPS.html");
print GPS <<XML;
<script type="text/javascript">
function loadScript( url, callback ) {
  var script = document.createElement( "script" )
  script.type = "text/javascript";
  script.onload = function() {
    callback();
  };
  script.src = url;
  document.getElementsByTagName( "head" )[0].appendChild( script );
}
loadScript("https://maps.googleapis.com/maps/api/js?key=$googleapikey&callback=initMap&libraries=&v=weekly", function() {
  var map = new google.maps.Map(document.getElementById('map'), {
    zoom: 2,
    center: new google.maps.LatLng(20, 10),
    mapTypeId: google.maps.MapTypeId.ROADMAP
  });
  var locations = [
XML
close (GPS);

# Get potentially already existing short Album names from target folders
find ( { wanted => \&WantedTARGET, }, $target_folder . "/" . $gallery_name);
sub WantedTARGET { push @dirs_in_target, $File::Find::name if -d; }
@dirs_in_target = sort { $b cmp $a } @dirs_in_target; # Z to A sorted directory list for all short album names already existing in target
foreach (@dirs_in_target) {
  my $album_in_t   = $_;
     $album_in_t   =~ s/.*\/(.*)\z/$1/g; # short album name from target directory
  push @album_in_target, $album_in_t;
}
print "\n---   Short name only of all albums already existing in target directory   ---\n@album_in_target\n\n";

# --- Add Album names to main html and IF NEEDED generate htmls for each album and album folders with small and large pics inside target directory --- #
my $album_index = 0;
my $picture_index_total = 0;
@album_names_s = ();
foreach (@dirs) {                                          # last if ($album_index >= 6); # Comment this to process more than 5 Albums
  $album_index++;
  my $album_name   = $_;
     $album_name   =~ s/.*\/(.*)\z/$1/g; # full album name from directory
  my $album_name_s = $album_name;
     $album_name_s =~ s/[^0-9a-zA-Z]//g; #remove everything but numbers and letters
     $album_name_s =  substr($album_name_s,0,20); #short album name w/o whitespace
  if    ($album_name_s ~~ @album_names_s) { $album_name_s =  $album_name_s . "1" ; } # adds a "1" to the album name in case it exists already
  elsif ($album_name_s ~~ @album_names_s) { $album_name_s =  $album_name_s . "2" ; } # adds a "2" to the album name in case  1 exists already
  elsif ($album_name_s ~~ @album_names_s) { $album_name_s =  $album_name_s . "3" ; } # adds a "3" to the album name in case  2 exists already
  elsif ($album_name_s ~~ @album_names_s) { $album_name_s =  $album_name_s . "4" ; } # adds a "4" to the album name in case  3 exists already
  elsif ($album_name_s ~~ @album_names_s) { $album_name_s =  $album_name_s . "5" ; } # adds a "5" to the album name in case  4 exists already
  push @album_names_s, $album_name_s;

  print "START --- Album No ($album_index) with the name \"$album_name\" will be processed now. ---\n";
  my $album_picture_index = 0;
  my $album_video_index   = 0;
  my $album_vidfc_index   = 0;
  if ( $album_name_s ~~ @album_in_target && $album_processing_only eq "yes" ) { print "!!! Album already exists !!!\n"; }
  else {

  find ( { wanted => \&WantedPICs, }, $_);
  sub WantedPICs { if ($_ =~ m/.\.jpe?g\z/i || $_ =~ m/.\.png\z/i || $_ =~ m/.\.heic\z/i || $_ =~ m/.\.mp4\z/i || $_ =~ m/.\.mov\z/i || $_ =~ m/.\.avi\z/i || $_ =~ m/.\.mpg\z/i) { push @picfilesindir, $File::Find::name; } }
  if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setreading $fhemdummyname album_picture 0 ; setreading $fhemdummyname album_picture_last " . scalar @picfilesindir . "\""; }
  @picfilesindir = sort { $a cmp $b } @picfilesindir; # A to Z sort the pictures in directory based on their filename

  mkdir     ("$target_folder/$gallery_name/$album_name_s"); # makes dir for current album from short name
  opendir my $dir, "$target_folder/$gallery_name/$album_name_s" or die "Cannot open directory: $!";
  my @pic_files_in_trg = readdir $dir; closedir $dir;
  open (A, "> $target_folder/$gallery_name/$album_name_s/${album_name_s}.html"); # generate html file for this album in album folder
  open (G, "> $target_folder/$gallery_name/$album_name_s/${album_name_s}_GPS.txt"); # generate GPS txt file for this album in album folder
  print A "  <div class=\"my-gallery\" itemscope itemtype=\"http://schema.org/ImageGallery\">\n";
  foreach (@picfilesindir) {                           # last if ($album_picture_index >= 4); # Comment this to process more than 4 pic
    $picture_index_total++;
    my $pic_full_path_src = $_;
    my $pic_file_name_trg = $_;
       $pic_file_name_trg =~ s/.*\/(.*)\z/$1/g; # full original pic name w/o directory path
       $pic_file_name_trg =~ s/\.jpe?g//ig; # remove ".jpg" ending if jpg
       $pic_file_name_trg =~ s/\.png//ig; # remove ".png" ending if png
       $pic_file_name_trg =~ s/\.mp4//ig; # remove ".mp4" ending if mp4
       $pic_file_name_trg =~ s/[^0-9a-zA-Z]//g; # remove everything but numbers and letters from the source picture file

    if ($_ =~ m/.\.mp4\z/i || $_ =~ m/.\.mov\z/i || $_ =~ m/.\.avi\z/i || $_ =~ m/.\.mpg\z/i) {
      print "M- ";
      my $vid_ori_s = sprintf "%.1f", (-s $pic_full_path_src) / 1000000;
      my $vid_ori_w = `ffprobe -v error -show_entries stream=width  -of default=nw=1:nk=1 \"$pic_full_path_src\"`; chomp($vid_ori_w);
      my $vid_ori_h = `ffprobe -v error -show_entries stream=height -of default=nw=1:nk=1 \"$pic_full_path_src\"`; chomp($vid_ori_h);
      ###### Check if file already exists in target directory and process only if not. ######
      if ( $pic_file_name_trg . "_vids.mp4" ~~ @pic_files_in_trg ) { print "!!! Movie already exists !!!\t"; } else {
          system "ffmpeg -loglevel panic -ss 1 -i \"$pic_full_path_src\" -vframes 1 -q:v 4 \"$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_vidpic.jpg\"";
          if ($vid_ori_w > $vid_ori_h) {
              system "ffmpeg -loglevel panic -i \"$pic_full_path_src\" -crf 27 -preset slow -tune zerolatency -vf \"scale=-2:'min(720,ih)'\" -r 24 -y \"$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_vids.mp4\"";
          } else {
              system "ffmpeg -loglevel panic -i \"$pic_full_path_src\" -crf 27 -preset slow -tune zerolatency -vf \"scale='min(720,iw)':-2\" -r 24 -y \"$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_vids.mp4\"";
          }
      }
      my $vid_new_s = sprintf "%.1f", (-s "$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_vids.mp4") / 1000000;
      my $vid_new_w = `ffprobe -v error -show_entries stream=width  -of default=nw=1:nk=1 $target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_vids.mp4`; chomp($vid_new_w);
      my $vid_new_h = `ffprobe -v error -show_entries stream=height -of default=nw=1:nk=1 $target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_vids.mp4`; chomp($vid_new_h);

      my $metadata = ImageInfo $pic_full_path_src;
      # GPSLatitude
      my $Lat   = $metadata->{GPSLatitude};
      my @LatA  = split / /, $Lat;
      my $LatD  = $LatA[0];
      my $LatM  = substr $LatA[2], 0, -1;
      my $LatS  = substr $LatA[3], 0, -1;
      my $LatP  = $LatA[4];
      my $LatDD = int( ($LatD + $LatM/60 + $LatS/3600) * 1000000 ) / 1000000;
      if ($LatP eq "S") { $LatDD = $LatDD * (-1) };
      # GPSLongitude
      my $Lon   = $metadata->{GPSLongitude};
      my @LonA  = split / /, $Lon;
      my $LonD  = $LonA[0];
      my $LonM  = substr $LonA[2], 0, -1;
      my $LonS  = substr $LonA[3], 0, -1;
      my $LonP  = $LonA[4];
      my $LonDD = int( ($LonD + $LonM/60 + $LonS/3600) * 1000000 ) / 1000000;
      if ($LonP eq "W") { $LonDD = $LonDD * (-1) };
      # Camera name
      my $camMak = $metadata->{Make};
      my $camMod = $metadata->{Model};
      my $pic_date = $metadata->{DateTimeOriginal};

      if ($pic_file_name_trg =~ /VideoIsFinalCut/i) {
      print A "    <figure class=\"vid VideoIsFinalCut\" itemprop=\"associatedMedia\" itemscope itemtype=\"http://schema.org/ImageObject\">\n";
      print "--- Found a VideoIsFinalCut here ---";
      $album_vidfc_index++;
      }
      else {
      print A "    <figure class=\"vid\" itemprop=\"associatedMedia\" itemscope itemtype=\"http://schema.org/ImageObject\">\n";
      }
      print A "       <video href=\"./$gallery_name/$album_name_s/${pic_file_name_trg}_vidpic.jpg\" poster=\"./$gallery_name/$album_name_s/${pic_file_name_trg}_vidpic.jpg\" controls loop data-size=\"${vid_new_w}x${vid_new_h}\" >\n";
      print A "         <source src=\"./$gallery_name/$album_name_s/${pic_file_name_trg}_vids.mp4\" type=\"video/mp4\"></source>\n";
      print A "       </video>\n";
      print A "      <figcaption itemprop=\"caption description\">Original file location: $pic_full_path_src<br>Ori: ${vid_ori_w}w x ${vid_ori_h}h pix ($vid_ori_s MB) / New: ${vid_new_w}w x ${vid_new_h}h pix ($vid_new_s MB)<br>$pic_date $camMak $camMod Lat:$LatDD Lon:$LonDD<br>&nbsp</figcaption>\n";
      print A "    </figure>\n";

      # --- Generate GPS data file per album --- #
      if ($LatDD == 0) {} else {
        print G "[\"Original file location: $pic_full_path_src<br>$pic_date $camMak $camMod Lat:$LatDD Lon:$LonDD<br><img src='./$gallery_name/$album_name_s/${pic_file_name_trg}_vids.mp4\'>\",$LatDD,$LonDD],\n";
      }

      $album_video_index++;
      my $timenow = localtime();
      print "$album_name_s | $startofscript -> $timenow | Alb/Vid/PicT:\t$album_index\t/\t$album_video_index\t/\t$picture_index_total\tMOVIE\n";
    }

    else {
      my $pic_s    = sprintf "%.1f", (-s $pic_full_path_src) / 1000000;
      my $pic_w    = `identify -format '%w' '$pic_full_path_src'`;
      my $pic_h    = `identify -format '%h' '$pic_full_path_src'`;
      ###### Check if file already exists in target directory and process only if not. ######
      if ( $pic_file_name_trg . "_m.jpg" ~~ @pic_files_in_trg ) { print "!!! Pic already exists !!!\t"; } else {
        system "convert -auto-orient \"$pic_full_path_src\" -resize 150x150^   -quality 70 \"$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_s.jpg\"";
        system "convert -auto-orient \"$pic_full_path_src\" -resize 2000x2000^ -quality 70 \"$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_m.jpg\"";
      }
      my $pic_s_re = sprintf "%.1f", (-s "$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_m.jpg") / 1000000;
      my $pic_w_re = `identify -format '%w' '$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_m.jpg'`;
      my $pic_h_re = `identify -format '%h' '$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_m.jpg'`;

      my $metadata = ImageInfo $pic_full_path_src;
      # GPSLatitude
      my $Lat   = $metadata->{GPSLatitude};
      my @LatA  = split / /, $Lat;
      my $LatD  = $LatA[0];
      my $LatM  = substr $LatA[2], 0, -1;
      my $LatS  = substr $LatA[3], 0, -1;
      my $LatP  = $LatA[4];
      my $LatDD = int( ($LatD + $LatM/60 + $LatS/3600) * 1000000 ) / 1000000;
      if ($LatP eq "S") { $LatDD = $LatDD * (-1) };
      # GPSLongitude
      my $Lon   = $metadata->{GPSLongitude};
      my @LonA  = split / /, $Lon;
      my $LonD  = $LonA[0];
      my $LonM  = substr $LonA[2], 0, -1;
      my $LonS  = substr $LonA[3], 0, -1;
      my $LonP  = $LonA[4];
      my $LonDD = int( ($LonD + $LonM/60 + $LonS/3600) * 1000000 ) / 1000000;
      if ($LonP eq "W") { $LonDD = $LonDD * (-1) };
      # Camera name
      my $camMak = $metadata->{Make};
      my $camMod = $metadata->{Model};
      my $pic_date = $metadata->{DateTimeOriginal};
      # print "$_ $h{$_}\n" for (keys $metadata); # print hash values to see all values in $metadata

      print A "    <figure class=\"pic\" itemprop=\"associatedMedia\" itemscope itemtype=\"http://schema.org/ImageObject\">\n";
      print A "      <a href=\"./$gallery_name/$album_name_s/${pic_file_name_trg}_m.jpg\" itemprop=\"contentUrl\" data-size=\"${pic_w_re}x${pic_h_re}\">\n";
      print A "        <img src=\"./$gallery_name/$album_name_s/${pic_file_name_trg}_s.jpg\" itemprop=\"thumbnail\" alt=\"Img\" />\n";
      print A "      </a>\n";
      print A "      <figcaption itemprop=\"caption description\">Original file location: $pic_full_path_src<br>Ori: ${pic_w}w x ${pic_h}h pix ($pic_s MB) / Med: ${pic_w_re}w x ${pic_h_re}h pix ($pic_s_re MB)<br>$pic_date $camMak $camMod Lat:$LatDD Lon:$LonDD<br>&nbsp</figcaption>\n";
      print A "    </figure>\n";

      # --- Generate GPS data file per album --- #
      if ($LatDD == 0) {} else {
        print G "[\"Original file location: $pic_full_path_src<br>$pic_date $camMak $camMod Lat:$LatDD Lon:$LonDD<br><img src='./$gallery_name/$album_name_s/${pic_file_name_trg}_s.jpg\'>\",$LatDD,$LonDD],\n";
      }
      $album_picture_index++;
      my $timenow = localtime();
      print "$album_name_s | $startofscript -> $timenow | Alb/Pic/PicT:\t$album_index\t/\t$album_picture_index\t/\t$picture_index_total\n";
      if ($fhemreporting eq "on_tmpoff") { system "perl $fhemplpath $fhemtelnetport \"setreading $fhemdummyname album_picture $album_picture_index\""; }
    }
  }
  print A "  </div>\n\n";
  print A <<XML;
<script>
var initPhotoSwipeFromDOM = function(gallerySelector) {
    // parse slide data (url, title, size ...) from DOM elements
    // (children of gallerySelector)
    var parseThumbnailElements = function(el) {
        var thumbElements = el.childNodes,
            numNodes = thumbElements.length,
            items = [],
            figureEl,
            linkEl,
            size,
            item;
        for(var i = 0; i < numNodes; i++) {
            figureEl = thumbElements[i]; // <figure> element
            // include only element nodes
            if(figureEl.nodeType !== 1) { continue; }
            linkEl = figureEl.children[0]; // <a> element

              // create slide object
              if (linkEl.tagName == 'VIDEO') {
                item = {
                         html: linkEl.outerHTML
                };
              } else {
                size = linkEl.getAttribute('data-size').split('x');
                item = {
                         src: linkEl.getAttribute('href'),
                         w: parseInt(size[0], 10),
                         h: parseInt(size[1], 10)
                };
              }

//            size = linkEl.getAttribute('data-size').split('x');
//            // create slide object
//            item = {
//                src: linkEl.getAttribute('href'),
//                w: parseInt(size[0], 10),
//                h: parseInt(size[1], 10)
//            };

            if(figureEl.children.length > 1) {
                // <figcaption> content
                item.title = figureEl.children[1].innerHTML;
            }
            if(linkEl.children.length > 0) {
                // <img> thumbnail element, retrieving thumbnail url
                item.msrc = linkEl.children[0].getAttribute('src');
            }
            item.el = figureEl; // save link to element for getThumbBoundsFn
            items.push(item);
        }
        return items;
    };
    // find nearest parent element
    var closest = function closest(el, fn) {
        return el && ( fn(el) ? el : closest(el.parentNode, fn) );
    };
    // triggers when user clicks on thumbnail
    var onThumbnailsClick = function(e) {
        e = e || window.event;
        e.preventDefault ? e.preventDefault() : e.returnValue = false;
        var eTarget = e.target || e.srcElement;
        // find root element of slide
        var clickedListItem = closest(eTarget, function(el) {
            return (el.tagName && el.tagName.toUpperCase() === 'FIGURE');
        });
        if(!clickedListItem) {
            return;
        }
        // find index of clicked item by looping through all child nodes
        // alternatively, you may define index via data- attribute
        var clickedGallery = clickedListItem.parentNode,
            childNodes = clickedListItem.parentNode.childNodes,
            numChildNodes = childNodes.length,
            nodeIndex = 0,
            index;
        for (var i = 0; i < numChildNodes; i++) {
            if(childNodes[i].nodeType !== 1) {
                continue;
            }
            if(childNodes[i] === clickedListItem) {
                index = nodeIndex;
                break;
            }
            nodeIndex++;
        }

        if(index >= 0) {
            // open PhotoSwipe if valid index found
            openPhotoSwipe( index, clickedGallery );
        }
        return false;
    };
    // parse picture index and gallery index from URL (#&pid=1&gid=2)
    var photoswipeParseHash = function() {
        var hash = window.location.hash.substring(1),
        params = {};
        if(hash.length < 5) {
            return params;
        }
        var vars = hash.split('&');
        for (var i = 0; i < vars.length; i++) {
            if(!vars[i]) {
                continue;
            }
            var pair = vars[i].split('=');
            if(pair.length < 2) {
                continue;
            }
            params[pair[0]] = pair[1];
        }
        if(params.gid) {
            params.gid = parseInt(params.gid, 10);
        }
        return params;
    };
    var openPhotoSwipe = function(index, galleryElement, disableAnimation, fromURL) {
        var pswpElement = document.querySelectorAll('.pswp')[0],
            gallery,
            options,
            items;
        items = parseThumbnailElements(galleryElement);
        // define options (if needed)
        options = {
            // define gallery index (for URL)
            galleryUID: galleryElement.getAttribute('data-pswp-uid'),
//            getThumbBoundsFn: function(index) {
//                // See Options -> getThumbBoundsFn section of documentation for more info // Note from me (Ben): This is mainly to make the zoom in/out animation from the ThumbPic
//                var thumbnail = items[index].el.getElementsByTagName('img')[0], // find thumbnail
//                    pageYScroll = window.pageYOffset || document.documentElement.scrollTop,
//                    rect = thumbnail.getBoundingClientRect();
//                return {x:rect.left, y:rect.top + pageYScroll, w:rect.width};
//            },
            preload: [1,3]
        };
        // PhotoSwipe opened from URL
        if(fromURL) {
            if(options.galleryPIDs) {
                // parse real index when custom PIDs are used
                // http://photoswipe.com/documentation/faq.html#custom-pid-in-url
                for(var j = 0; j < items.length; j++) {
                    if(items[j].pid == index) {
                        options.index = j;
                        break;
                    }
                }
            } else {
                // in URL indexes start from 1
                options.index = parseInt(index, 10) - 1;
            }
        } else {
            options.index = parseInt(index, 10);
        }
        // exit if index not found
        if( isNaN(options.index) ) {
            return;
        }
        if(disableAnimation) {
            options.showAnimationDuration = 0;
        }
        // Pass data to PhotoSwipe and initialize it
        gallery = new PhotoSwipe( pswpElement, PhotoSwipeUI_Default, items, options);
        gallery.init();
    };
    // loop through all gallery elements and bind events
    var galleryElements = document.querySelectorAll( gallerySelector );
    for(var i = 0, l = galleryElements.length; i < l; i++) {
        galleryElements[i].setAttribute('data-pswp-uid', i+1);
        galleryElements[i].onclick = onThumbnailsClick;
    }
    // Parse URL and open gallery if it contains #&pid=3&gid=1
    var hashData = photoswipeParseHash();
    if(hashData.pid && hashData.gid) {
        openPhotoSwipe( hashData.pid ,  galleryElements[ hashData.gid - 1 ], true, true );
    }
};
// execute above function
initPhotoSwipeFromDOM('.my-gallery');
</script>
XML
  close (A);
  close (G);
  }

  # --- Generate middle part of main html of Gallery in server root directory --- #
  if    (0 == substr($album_name,1,4) % 2) { $htmlclass = "even"; }
  elsif (1 == substr($album_name,1,4) % 2) { $htmlclass = "odd"; }
  else                                     { $htmlclass = "other"; }
  $lineclass = "";
  @linlabel  = ();
  $linelabel = "";
  if ($album_picture_index > 0) { $lineclass = $lineclass . " linpic"; $linlabel[0] = $album_picture_index . " pics"; }
  if ($album_video_index > 0)   { $lineclass = $lineclass . " linvid"; $linlabel[1] = $album_video_index   . " vids"; }
  if ($album_vidfc_index > 0)   { $lineclass = $lineclass . " linvfc"; $linlabel[2] = $album_vidfc_index   . " vfcs"; }
  $linelabel = join(" / ", @linlabel);
  open  (H,">> $target_folder/$gallery_name.html");
  print  H "  <div class=\"lineitem$lineclass\"><a type=\"button\" class=\"collapsible $htmlclass\" filetoload=\"./$gallery_name/$album_name_s/${album_name_s}.html\">$album_name <span class=\"small\">(" . $linelabel . ")</span></a><div></div></div>\n";
  close (H);
  print "END   --- Album No ($album_index) with the name \"$album_name\" has been processed. ---\n\n";
  if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setreading $fhemdummyname album $album_index\""; }
  undef @picfilesindir;
}

# --- Amend all GPS.txt files in albums to GPS.html and generate END of overall GPS.html file --- #
find ( { wanted => \&WantedGPS, }, $target_folder . "/" . $gallery_name);
sub WantedGPS { if ( $File::Find::name =~ /.*_GPS\.txt/ ) { push @gpsfile, $File::Find::name } }
open  (GPS, ">> $target_folder/$gallery_name/GPS.html");
foreach (@gpsfile) {
  open (GPSF, "< $_");
  while (<GPSF>) {
    print GPS;
  }
  close (GPSF);
}
print  GPS <<XML;
  ];
  var infowindow = new google.maps.InfoWindow();
  var marker, i;
  for (i = 0; i < locations.length; i++) {
    marker = new google.maps.Marker({
      position: new google.maps.LatLng(locations[i][1], locations[i][2]),
      map: map
    });
    google.maps.event.addListener(marker, 'click', (function(marker, i) {
      return function() {
        infowindow.setContent(locations[i][0]);
        infowindow.open(map, marker);
      }
    })(marker, i));
  }
  google.maps.event.addListener(map, "click", function(event) {
    infowindow.close();
  });
});
</script>
<div id="map" style="width: 100vw; height: 100vh;"></div>
XML
close (GPS);

# --- Generate END of main html of Gallery in server root directory --- #
open  (H, ">> $target_folder/$gallery_name.html");
print  H <<XML;
 </list>
 </div>

<footer>
  ---   In the gallery are $album_index albums.   ---<br>
  ---   There are $picture_index_total pictures were processed during last update.   ---<br>
  ---   For help write to <a style="color: black;" href= "mailto:b.neunstoecklin\@gmail.com">b.neunstoecklin\@gmail.com</a>   ---<br>
  ---   Thanks to Dmitry Semenov for the <a style="color: black;" href= "https://photoswipe.com" target="_blank">photo swipe</a> functionallity of this picture gallery   ---
  <div class="bottomgalleryname">$gallery_name_long</div>
  <img src="./LibPicGallery/picgallery_icon_bot.png" itemprop="thumbnail" alt="Img" />
</footer>

</body>
</html>
XML
close (H);
if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setstate $fhemdummyname finished; setreading $fhemdummyname script_status finished\""; }
