/** 
 * tile-dem-srtm
 * -------------
 * Efficiently splits raw NASA SRTM Digital Elevation Model data files into tiles
 *    http://srtm.csi.cgiar.org/
 *
 * Also usable with Mars MEGDR data:
 *    http://pds-geosciences.wustl.edu/missions/mgs/megdr.html
 *
 * Build with:
 *    g++ -Wall -pedantic -I/usr/include/ImageMagick/ -lMagick++ tile-dem-srtm.cpp -o tile-dem-srtm 
 *
*/

#include <stdint.h>
#include <math.h>
#include <getopt.h>
#include <iostream>
#include <ostream>
#include <fstream>
#include <string>
#include <map>
#include <vector>
#include <ImageMagick/Magick++.h>

uint16_t endian_swap(uint16_t& num) {
  return (num>>8) | (num<<8);
}

std::string program_usage(std::string cname="./bluemarble") {
  std::string ret = "Usage: " + cname;
  ret +=
    " -f <sourcefile> -w <sourcewidth> -h <sourceheight> -s <tilesize> -x <startx> -y <starty> -X <countx> -Y <county> -c\n"
    "\n"
    "  -f, --sourcefile      Raw binary file to load from\n"
    "  -w, --sourcewidth     Pixels per line (x resolution)\n"
    "  -h, --sourceheight    Number of lines (y resolution)\n"
    "  -s, --tilesize        Tilesize to generate [default: 256]\n"
    "  -x, --startx          Start column [default: 0]\n"
    "  -y, --starty          Start row [default: 0]\n"
    "  -X, --countx          Number of columns to generate [default: MAXX]\n"
    "  -Y, --county          Number of rows to generate [default: MAXY]\n"
    "  -c, --color           Generate color tiles instead of greyscale\n";

  return ret;
}

typedef std::map< size_t, std::vector< int16_t > > ImageData;

class ImageTile {
  protected:
    size_t col;
    size_t row;
    size_t size;
    ImageData idata;
    static std::map<size_t, Magick::Image *> tmpimage;

  public:
    ImageTile(size_t size, size_t col, size_t row, ImageData image) {
      this->col = col;
      this->row = row;
      this->size = size;
      this->idata = image;
    }
    static Magick::Image *getTemporaryImage(size_t size) {
      if (ImageTile::tmpimage.find(size) == ImageTile::tmpimage.end()) {
        //std::cout << "Temporary image not found, creating" << std::endl;
        ImageTile::tmpimage[size] = new Magick::Image(Magick::Geometry(size, size), Magick::Color("black"));
        ImageTile::tmpimage[size]->magick("png");
      }
      return ImageTile::tmpimage[size];
    }
    void createImage(bool greyscale=false) {
      //Magick::Image newimg(Magick::Geometry(this->size, this->size), Magick::Color("black"));
      Magick::Image *newimg = ImageTile::getTemporaryImage(this->size);

      ImageData::const_iterator it; 
      size_t y = 0;
      uint8_t *rgb;
      int16_t max = -32767, min = 32767;
      float cscale = MaxRGB / 256.0;

      for (it = this->idata.begin(); it != this->idata.end(); it++) {
        size_t xsize = ((*it).second).size();
        for (size_t x = 0; x < xsize; x++) {
          //int16_t val = ((*it).second[x] / 2) + 32768;
          int16_t val = ((*it).second[x]);

          rgb = (uint8_t *) &val;
          //newimg->pixelColor(x, y, Magick::Color(rgb[0] / 255.0 * MaxRGB, rgb[1] / 255.0 * MaxRGB, 0));
          if (greyscale) {
            int16_t shade = ((val + 32768.0) / 65536.0) * MaxRGB;
            //int16_t shade = ((val > 0 ? val : 0) / 65535.0) * MaxRGB;
            newimg->pixelColor(x, y, Magick::Color(shade, shade, shade));
          } else {
            // encode 16-bit values into 8-bit red and green channels
            // for negative values, set the blue channel to 256

            // TODO - this format only makes sense for WebGL which doesn't have support for 16-bit
            //        greyscale PNGs.  We should really support other more standardized formats too

            if (val < 0) {
              newimg->pixelColor(x, y, Magick::Color(floor(-val / 256.0) * cscale, (-val % 256) * cscale, 256 * cscale));
            } else {
              newimg->pixelColor(x, y, Magick::Color(floor(val / 256.0) * cscale, (val % 256) * cscale, 0));
            }
          }
          if (val < min) min = val;
          if (val > max) max = val;
        }
        y++;
      }
      char fname[128];
      sprintf(fname, "%d_%d.png", (int) this->col, (int) this->row);  
      newimg->write(fname);
      std::cout << fname << " " << std::flush;
      std::cout << "Height range: " << min << " to " << max << std::endl;
    }
    friend std::ostream& operator<<(std::ostream& os, const ImageTile& img);
};
std::map<size_t, Magick::Image *> ImageTile::tmpimage;

class DataFile {
  private:
    std::ifstream file;
    bool loaded;
    size_t width;
    size_t height;

  public:
    DataFile(std::string fname, size_t width, size_t height) {
      this->width = width;
      this->height = height;
      this->loaded = false;
      std::cout << "Open file: " << fname << "...";
      this->file.open(fname.c_str(), std::ios::in | std::ios::binary);
      if (this->file.is_open()) {
        std::cout << "success!" << std::endl;
        this->loaded = true;
      } else {
        std::cout << "failure!" << std::endl;
      }
    }
    ~DataFile() {
      std::cout << "Closing file" << std::endl;
      this->file.close();
    }
    ImageData getData(size_t tlx, size_t tly, size_t sizex, size_t sizey) {
      ImageData ret;
      if (this->loaded) {
        //std::cout << "getting data: (" << tlx << ", " << tly << ") => (" << (tlx + sizex) << ", " << (tly + sizey) << ")" << std::endl;
        uint16_t *pixeldata = new uint16_t[sizex];
        for (size_t y = tly; y < tly + sizey; y++) {
          size_t offset = (this->width * y + tlx) * sizeof(int16_t); 
          std::streamsize readsize = sizeof(int16_t) * sizex;
//std::cout << "seek to offset " << offset << std::endl;
          this->file.seekg(offset);
          this->file.read((char *)pixeldata, readsize);
//std::cout << (char *)pixeldata << " (read " << this->file.gcount() << " bytes)" << std::endl;

          if (this->file.gcount() < readsize) {
            std::cout << "ERROR - read of " << readsize << " bytes at offset " << offset << "failed, got " << this->file.gcount() << " bytes" << std::endl;
          } else {
            for (size_t x = 0; x < sizex; x++) {
              ret[y].push_back(endian_swap(pixeldata[x]));
            }
          }
        }
        delete[] pixeldata;
      } else {
        std::cout << "Can't read data, not loaded!" << std::endl;
      }
      return ret; 
    }
    ImageTile *getTile(size_t tilesize, size_t x, size_t y) {
      if (x * tilesize < this->width && y * tilesize < this->height) {
        size_t width = tilesize, height = tilesize;
        if ((x + 1) * tilesize > this->width) {
          width = this->width - x * tilesize;
        }
        if ((y + 1) * tilesize > this->height) {
          height = this->height - y * tilesize;
        }
        return new ImageTile(tilesize, x, y, this->getData(x * tilesize, y * tilesize, width, height));
      }
      return NULL;
    }

};
std::ostream& operator<<(std::ostream& os, const ImageTile& img) {
  ImageData::const_iterator it; 
  int y = 0;
  uint8_t *rgb;
  for (it = img.idata.begin(); it != img.idata.end(); it++) {
    int xsize = ((*it).second).size();
    os << y++ << ": ";
    for (int i = 0; i < xsize; i++) {
      int16_t val = (*it).second[i];
      rgb = (uint8_t *) &val;
      os << val << " [" << (int)rgb[0] << ", " << (int)rgb[1] << "]" << (i != xsize-1 ? ", " : "");
    }
    os << std::endl;
  }
  os << std::endl;
  return os;
}


int main(int argc, char **argv) {
  // TODO - these should be arguments
  size_t tilesize = 256;
  std::string sourcefile = "";
  size_t sourcewidth = 86400;
  size_t sourceheight = 43200;
  size_t tilex = 0, tiley = 0;
  size_t tilecountx = 0, tilecounty = 0;
  bool greyscale = true;

  int c;
  while ((c = getopt(argc, argv, "f:s:w:h:x:X:y:Y:c")) != -1) {
    switch (c) {
      case 'f': // source file
        sourcefile = optarg;
        break;
      case 'w': // width
        sourcewidth = atoi(optarg);
        break;
      case 'h': // height
        sourceheight = atoi(optarg);
        break;
      case 's': // tilesize
        tilesize = atoi(optarg);
        break;
      case 'x': // col start
        tilex = atoi(optarg);
        break;
      case 'y': // row start
        tiley = atoi(optarg);
        break;
      case 'X': // col count
        tilecountx = atoi(optarg);
        break;
      case 'Y': // row count
        tilecounty = atoi(optarg);
        break;
      case 'c': // color (16-bit encoded in RGBA)
        greyscale = false;
        break;
    }
  }

  if (sourcefile == "") {
    //std::cout << "Error: must specify filename using -f" << std::endl;
    std::cout << std::endl << program_usage() << std::endl;
    return 1;
  }

  Magick::InitializeMagick(argv[0]);
  DataFile foo(sourcefile, sourcewidth, sourceheight);

  if (tilecountx == 0) {
    tilecountx = ceil(sourcewidth / tilesize) - tilex;
  }
  if (tilecounty == 0) {
    tilecounty = ceil(sourceheight / tilesize) - tiley;
  }

//std::cout << "do it: " << (tiley + tilecounty) << std::endl;
  std::cout << "Generating " << tilesize << "x" << tilesize << (greyscale ? " greyscale" : " color") << " tiles (" << tilex << "x" << tiley << ") => (" << (tilecountx + tilex) << ", " << (tilecounty + tiley) << "): " << std::flush;
  for (size_t y = tiley; y <= tiley + tilecounty; y++) {
    for (size_t x = tilex; x <= tilex + tilecountx; x++) {
//std::cout << "do it: " << x << ", " << y << std::endl;
      ImageTile *tile = foo.getTile(tilesize, x, y);
      if (tile) {
        //std::cout << "Got tile: " << *tile;
        tile->createImage(greyscale);
        delete tile;
      }
    }
  }
  std::cout << std::endl;
  return 0;
}
