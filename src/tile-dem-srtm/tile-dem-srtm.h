//
//  tile-dem-srtm.h
//
//  Created by scott on 3/2/14.
//

#include <ImageMagick/Magick++.h>

#if (QuantumDepth == 8)
#define TileMaxRGB  ((Magick::Quantum) 255)
#elif (QuantumDepth == 16)
#define TileMaxRGB  ((Magick::Quantum) 65535)
#elif (QuantumDepth == 32)
#define TileMaxRGB  ((Magick::Quantum) 4294967295U)
#endif
