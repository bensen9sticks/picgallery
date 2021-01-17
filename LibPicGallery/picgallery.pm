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
#  GITHUB Homepage:
#
#  picgallery.pm 2021-01-06 bensen9
#
###############################################################################

# --------------------------------------------------------------- #
# --- Adapt the input variables below according to your needs --- #
# --------------------------------------------------------------- #

# Mandatory inputs
my $albumdepthlevel   = 2; # folder level below the source folder used to generate albums
my $source_folder     = "../ExampleGallerySource"; # Levels 1 # "/Volumes/Data SSD/Steffi/Fotos"; # Levels 2 # absolut root folder where all your picture are, finish without slash
my $target_folder     = "../"; # absolut target folder of your webserver. SMB mount the folder in case you don't run the scripy on your server. In this folder a folder with your gallery name will be generate and a gallery_name.html to load the page.
my $gallery_name_long = "Example Pic Gallery"; # name of your gallery
my $googleapikey      = "YOURKEYHERE"; # insert your google API key here to enable the google maps feature
my $uicolor           = boy; # choose between boy or girl

my $fhemreporting     = off; # choose between on or off
my $fhemplpath        = "/Applications/Fhem/fhem.pl";
my $fhemtelnetport    = 7072;
my $fhemdummyname     = "PicGalleryStat";

# ------------------------------------------------------------------------------ #
# --- Start of scrip here, don't change if you don't know what you are doing --- #
# ------------------------------------------------------------------------------ #
use 5.010;
use File::Find;
use Image::ExifTool ':Public';
use Image::Scale;
# use strict;
# use warnings;

$"= "\n";
my $startofscript = localtime();
my $gallery_name = $gallery_name_long;
   $gallery_name =~ s/[^0-9a-zA-Z]//g; # remove everything but numbers and letters from the gallery name
if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setstate $fhemdummyname running; setreading $fhemdummyname script_status running\""; }

# Development and debug variables
my $pictures_in_album_to_be_processed = 1000000; # use this during development to limit the amount of pictures processed within a folder-album. Make number higher than the total amount of pictures in your biggest album to ensure total processing (e.g. 1000000).

# Make main directory on server for albums and album html files
mkdir ("$target_folder/$gallery_name");
my $album_index = 0;
my $picture_index_total = 0;

# Get Album names from source folder names based on depth level
my $startingfolderdepth = $source_folder =~ tr[/][];
my $addfolderdepth = $albumdepthlevel;
my $totalfolderdepth = $startingfolderdepth + $addfolderdepth;
find ( { preprocess => \&PreProcess, wanted => \&Wanted, }, $source_folder);
sub PreProcess { my $currentdepth = $File::Find::dir =~ tr[/][]; return grep { -d} @_ if $currentdepth < $totalfolderdepth; }
sub Wanted     { if ( ($File::Find::name =~ tr[/][]) == $totalfolderdepth && $File::Find::name !~ m/\.photos?library/i && $File::Find::name !~ m/synchronisieren/i ) {
    push @dirs, $File::Find::name if -d; }
}
@dirs = sort { $b cmp $a } @dirs; # Z to A sorted directory list based on $albumdepthlevel
print "\n---   Full path of all albums in source directory   ---\n@dirs\n\n";
if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setreading $fhemdummyname album 0 ; setreading $fhemdummyname album_last " . scalar @dirs . "\""; }

# --- Generate start of main html of Gallery in server root directory --- #
open  (H, "> $target_folder/$gallery_name.html");
print  H <<XML;
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content = "width=device-width, initial-scale=0.5, user-scalable=no, viewport-fit=cover" />
  <meta name="apple-mobile-web-app-title" content="$gallery_name" />
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default" />

XML
if ($uicolor eq "girl") {
  print H "<link rel=\"apple-touch-icon\" href=\"./LibPicGallery/iOSicon-gallery_g.png\">\n";
}
else {
  print H "<link rel=\"apple-touch-icon\" href=\"./LibPicGallery/iOSicon-gallery_b.png\">\n";
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
      list = document.getElementById("myUL");
      line = list.getElementsByTagName("line");
      for (i = 0; i < line.length; i++) {
          a = line[i].getElementsByTagName("a")[0];
          txtValue = a.textContent || a.innerText;
          if (txtValue.toUpperCase().indexOf(filter) > -1) {
              line[i].style.display = "";
          } else {
              line[i].style.display = "none";
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
   <div>$gallery_name_long</div>
 </pagehead>

 <div class="inputback"><input type="text" id="myInput" onkeyup="SearchField()" placeholder="Search for events or album names..." title="Type in a name"></div>

 <div class="listbackg">
 <list id="myUL">
  <line><a type="button" class="collapsible google" filetoload=\"./$gallery_name/GPS.html\">Pins on Google Maps <span class="small">(for pictures with GPS information only)</span></a><div></div></line>
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
foreach (@dirs) {
  my $album_name   = $_;
     $album_name   =~ s/.*\/(.*)\z/$1/g; # full album name from directory
  my $album_name_s = $album_name;
     $album_name_s =~ s/[^0-9a-zA-Z]//g; #remove everything but numbers and letters
     $album_name_s =  substr($album_name_s,0,20); #short album name w/o whitespace
  find ( { wanted => \&WantedPICs, }, $_);
  sub WantedPICs { if ($_ =~ m/.\.jpe?g\z/i) { push @picfilesindir, $File::Find::name; } }
  my $album_picture_index = 0;
  if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setreading $fhemdummyname album_picture 0 ; setreading $fhemdummyname album_picture_last " . scalar @picfilesindir . "\""; }
  print "START --- Album No (" . ($album_index+1) . ") with the name \"$album_name\" will be processed now. ---\n";

  # --- Check if Album needs processing based on: check if generated short album name $album_name_s exists in target directory. Only process if not ???
  if ( grep( /^$album_name_s$/, @album_in_target ) ) {
    print "Album aready exists in target folder and processing will be skipped.\n";
  }
  else {
      mkdir     ("$target_folder/$gallery_name/$album_name_s"); # makes dir for current album from short name
      open (A, "> $target_folder/$gallery_name/$album_name_s/${album_name_s}.html"); # generate html file for this album in album folder
      open (G, "> $target_folder/$gallery_name/$album_name_s/${album_name_s}_GPS.txt"); # generate GPS txt file for this album in album folder
      print A "  <div class=\"my-gallery\" itemscope itemtype=\"http://schema.org/ImageGallery\">\n";
      foreach (@picfilesindir) {
                                last if ($album_picture_index >= $pictures_in_album_to_be_processed);
        my $pic_full_path_src = $_;
        my $pic_file_name_trg = $_;
           $pic_file_name_trg =~ s/.*\/(.*)\z/$1/g; # full original pic name w/o directory path
           $pic_file_name_trg =~ s/\.jpe?g//ig; # remove ".jpg" ending
           $pic_file_name_trg =~ s/[^0-9a-zA-Z]//g; # remove everything but numbers and letters from the source picture file

        my $img = Image::Scale->new($pic_full_path_src);
        my $pic_h    = $img->height();
        my $pic_w    = $img->width();
        if ($pic_w > $pic_h) {
           $img->resize_gd_fixed_point( { height => 150 } );
        } else {
           $img->resize_gd_fixed_point( { width => 150 } );
        }
           $img->save_jpeg("$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_s.jpg",70);
           $img->resize_gd_fixed_point( { height => 2000 } );
           $img->save_jpeg("$target_folder/$gallery_name/$album_name_s/${pic_file_name_trg}_m.jpg",70);
        my $pic_h_re = $img->resized_height();
        my $pic_w_re = $img->resized_width();

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
        # print "$_ $h{$_}\n" for (keys $metadata); # print hash values

        print A "    <figure itemprop=\"associatedMedia\" itemscope itemtype=\"http://schema.org/ImageObject\">\n";
        print A "      <a href=\"./$gallery_name/$album_name_s/${pic_file_name_trg}_m.jpg\" itemprop=\"contentUrl\" data-size=\"${pic_w_re}x${pic_h_re}\">\n";
        print A "        <img src=\"./$gallery_name/$album_name_s/${pic_file_name_trg}_s.jpg\" itemprop=\"thumbnail\" alt=\"Img\" />\n";
        print A "      </a>\n";
        print A "      <figcaption itemprop=\"caption description\">Original file location: $pic_full_path_src<br>Ori: ${pic_h}x${pic_w}pix / Med: ${pic_h_re}x${pic_w_re}pix<br>$pic_date $camMak $camMod Lat:$LatDD Lon:$LonDD</figcaption>\n";
        print A "    </figure>\n";

        # --- Generate GPS data file per album --- #
        if ($LatDD == 0) {} else {
          print G "[\"Original file location: $pic_full_path_src<br>$pic_date $camMak $camMod Lat:$LatDD Lon:$LonDD<br><img src='./$gallery_name/$album_name_s/${pic_file_name_trg}_s.jpg\'>\",$LatDD,$LonDD],\n";
        }
        $album_picture_index++;
        $picture_index_total++;
        my $timenow = localtime();
        print "$startofscript -> $timenow  |  Index Album / PicInAlbum / PicTotal:\t" . ($album_index+1) . "\t/\t$album_picture_index\t/\t$picture_index_total\n";
        if ($fhemreporting eq "on") { system "perl $fhemplpath $fhemtelnetport \"setreading $fhemdummyname album_picture $album_picture_index\""; }
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
            if(figureEl.nodeType !== 1) {
                continue;
            }
            linkEl = figureEl.children[0]; // <a> element
            size = linkEl.getAttribute('data-size').split('x');
            // create slide object
            item = {
                src: linkEl.getAttribute('href'),
                w: parseInt(size[0], 10),
                h: parseInt(size[1], 10)
            };

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
            getThumbBoundsFn: function(index) {
                // See Options -> getThumbBoundsFn section of documentation for more info
                var thumbnail = items[index].el.getElementsByTagName('img')[0], // find thumbnail
                    pageYScroll = window.pageYOffset || document.documentElement.scrollTop,
                    rect = thumbnail.getBoundingClientRect();
                return {x:rect.left, y:rect.top + pageYScroll, w:rect.width};
            },
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
  open  (H,">> $target_folder/$gallery_name.html");
  print  H "  <line><a type=\"button\" class=\"collapsible $htmlclass\" filetoload=\"./$gallery_name/$album_name_s/${album_name_s}.html\">$album_name <span class=\"small\">(" . scalar(@picfilesindir) . " pics)</span></a><div></div></line>\n";
  close (H);
  $album_index++;
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
