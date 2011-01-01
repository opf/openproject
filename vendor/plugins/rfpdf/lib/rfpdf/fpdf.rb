# Ruby FPDF 1.53d
# FPDF 1.53 by Olivier Plathey ported to Ruby by Brian Ollenberger
# Copyright 2005 Brian Ollenberger
# Please retain this entire copyright notice. If you distribute any
# modifications, place an additional comment here that clearly indicates
# that it was modified. You may (but are not  send any useful modifications that you make
# back to me at http://zeropluszero.com/software/fpdf/

# Bug fixes, examples, external fonts, JPEG support, and upgrade to version
# 1.53 contributed by Kim Shrier.
#
# Bookmark support contributed by Sylvain Lafleur.
#
# EPS support contributed by Thiago Jackiw, ported from the PHP version by Valentin Schmidt.
#
# Bookmarks contributed by Sylvain Lafleur.
#
# 1.53 contributed by Ed Moss
#   Handle '\n' at the beginning of a string
# Bookmarks contributed by Sylvain Lafleur.

require 'date'
require 'zlib'

class FPDF
    FPDF_VERSION = '1.53d'

    Charwidths =  {
        'courier'=>[600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600],
        
        'courierB'=>[600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600],
        
        'courierI'=>[600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600],
        
        'courierBI'=>[600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600],
        
        'helvetica'=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, 350, 556, 350, 222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 222, 222, 333, 333, 350, 556, 1000, 333, 1000, 500, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 260, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 556, 537, 278, 333, 333, 365, 556, 834, 834, 834, 611, 667, 667, 667, 667, 667, 667, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 500, 556, 556, 556, 556, 278, 278, 278, 278, 556, 556, 556, 556, 556, 556, 556, 584, 611, 556, 556, 556, 556, 500, 556, 500],
        
        'helveticaB'=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584, 350, 556, 350, 278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 278, 278, 500, 500, 350, 556, 1000, 333, 1000, 556, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 280, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 611, 556, 278, 333, 333, 365, 556, 834, 834, 834, 611, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 556, 556, 556, 556, 556, 278, 278, 278, 278, 611, 611, 611, 611, 611, 611, 611, 584, 611, 611, 611, 611, 611, 556, 611, 556],
        
        'helveticaI'=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, 350, 556, 350, 222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 222, 222, 333, 333, 350, 556, 1000, 333, 1000, 500, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 260, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 556, 537, 278, 333, 333, 365, 556, 834, 834, 834, 611, 667, 667, 667, 667, 667, 667, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 500, 556, 556, 556, 556, 278, 278, 278, 278, 556, 556, 556, 556, 556, 556, 556, 584, 611, 556, 556, 556, 556, 500, 556, 500],
        
        'helveticaBI'=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584, 350, 556, 350, 278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 278, 278, 500, 500, 350, 556, 1000, 333, 1000, 556, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 280, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 611, 556, 278, 333, 333, 365, 556, 834, 834, 834, 611, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 556, 556, 556, 556, 556, 278, 278, 278, 278, 611, 611, 611, 611, 611, 611, 611, 584, 611, 611, 611, 611, 611, 556, 611, 556],
        
        'times'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 408, 500, 500, 833, 778, 180, 333, 333, 500, 564, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 564, 564, 564, 444, 921, 722, 667, 667, 722, 611, 556, 722, 722, 333, 389, 722, 611, 889, 722, 722, 556, 722, 667, 556, 611, 722, 722, 944, 722, 722, 611, 333, 278, 333, 469, 500, 333, 444, 500, 444, 500, 444, 333, 500, 500, 278, 278, 500, 278, 778, 500, 500, 500, 500, 333, 389, 278, 500, 500, 722, 500, 500, 444, 480, 200, 480, 541, 350, 500, 350, 333, 500, 444, 1000, 500, 500, 333, 1000, 556, 333, 889, 350, 611, 350, 350, 333, 333, 444, 444, 350, 500, 1000, 333, 980, 389, 333, 722, 350, 444, 722, 250, 333, 500, 500, 500, 500, 200, 500, 333, 760, 276, 500, 564, 333, 760, 333, 400, 564, 300, 300, 333, 500, 453, 250, 333, 300, 310, 500, 750, 750, 750, 444, 722, 722, 722, 722, 722, 722, 889, 667, 611, 611, 611, 611, 333, 333, 333, 333, 722, 722, 722, 722, 722, 722, 722, 564, 722, 722, 722, 722, 722, 722, 556, 500, 444, 444, 444, 444, 444, 444, 667, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 500, 500, 500, 500, 500, 500, 564, 500, 500, 500, 500, 500, 500, 500, 500],
        
        'timesB'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 555, 500, 500, 1000, 833, 278, 333, 333, 500, 570, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 570, 500, 930, 722, 667, 722, 722, 667, 611, 778, 778, 389, 500, 778, 667, 944, 722, 778, 611, 778, 722, 556, 667, 722, 722, 1000, 722, 722, 667, 333, 278, 333, 581, 500, 333, 500, 556, 444, 556, 444, 333, 500, 556, 278, 333, 556, 278, 833, 556, 500, 556, 556, 444, 389, 333, 556, 500, 722, 500, 500, 444, 394, 220, 394, 520, 350, 500, 350, 333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333, 1000, 350, 667, 350, 350, 333, 333, 500, 500, 350, 500, 1000, 333, 1000, 389, 333, 722, 350, 444, 722, 250, 333, 500, 500, 500, 500, 220, 500, 333, 747, 300, 500, 570, 333, 747, 333, 400, 570, 300, 300, 333, 556, 540, 250, 333, 300, 330, 500, 750, 750, 750, 500, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 389, 389, 389, 389, 722, 722, 778, 778, 778, 778, 778, 570, 778, 722, 722, 722, 722, 722, 611, 556, 500, 500, 500, 500, 500, 500, 722, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 556, 500, 500, 500, 500, 500, 570, 500, 556, 556, 556, 556, 500, 556, 500],
        
        'timesI'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 420, 500, 500, 833, 778, 214, 333, 333, 500, 675, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 675, 675, 675, 500, 920, 611, 611, 667, 722, 611, 611, 722, 722, 333, 444, 667, 556, 833, 667, 722, 611, 722, 611, 500, 556, 722, 611, 833, 611, 556, 556, 389, 278, 389, 422, 500, 333, 500, 500, 444, 500, 444, 278, 500, 500, 278, 278, 444, 278, 722, 500, 500, 500, 500, 389, 389, 278, 500, 444, 667, 444, 444, 389, 400, 275, 400, 541, 350, 500, 350, 333, 500, 556, 889, 500, 500, 333, 1000, 500, 333, 944, 350, 556, 350, 350, 333, 333, 556, 556, 350, 500, 889, 333, 980, 389, 333, 667, 350, 389, 556, 250, 389, 500, 500, 500, 500, 275, 500, 333, 760, 276, 500, 675, 333, 760, 333, 400, 675, 300, 300, 333, 500, 523, 250, 333, 300, 310, 500, 750, 750, 750, 500, 611, 611, 611, 611, 611, 611, 889, 667, 611, 611, 611, 611, 333, 333, 333, 333, 722, 667, 722, 722, 722, 722, 722, 675, 722, 722, 722, 722, 722, 556, 611, 500, 500, 500, 500, 500, 500, 500, 667, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 500, 500, 500, 500, 500, 500, 675, 500, 500, 500, 500, 500, 444, 500, 444],
        
        'timesBI'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 389, 555, 500, 500, 833, 778, 278, 333, 333, 500, 570, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 570, 500, 832, 667, 667, 667, 722, 667, 667, 722, 778, 389, 500, 667, 611, 889, 722, 722, 611, 722, 667, 556, 611, 722, 667, 889, 667, 611, 611, 333, 278, 333, 570, 500, 333, 500, 500, 444, 500, 444, 333, 500, 556, 278, 278, 500, 278, 778, 556, 500, 500, 500, 389, 389, 278, 556, 444, 667, 500, 444, 389, 348, 220, 348, 570, 350, 500, 350, 333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333, 944, 350, 611, 350, 350, 333, 333, 500, 500, 350, 500, 1000, 333, 1000, 389, 333, 722, 350, 389, 611, 250, 389, 500, 500, 500, 500, 220, 500, 333, 747, 266, 500, 606, 333, 747, 333, 400, 570, 300, 300, 333, 576, 500, 250, 333, 300, 300, 500, 750, 750, 750, 500, 667, 667, 667, 667, 667, 667, 944, 667, 667, 667, 667, 667, 389, 389, 389, 389, 722, 722, 722, 722, 722, 722, 722, 570, 722, 722, 722, 722, 722, 611, 611, 500, 500, 500, 500, 500, 500, 500, 722, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 556, 500, 500, 500, 500, 500, 570, 500, 556, 556, 556, 556, 444, 500, 444],
        
        'symbol'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 713, 500, 549, 833, 778, 439, 333, 333, 500, 549, 250, 549, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 549, 549, 549, 444, 549, 722, 667, 722, 612, 611, 763, 603, 722, 333, 631, 722, 686, 889, 722, 722, 768, 741, 556, 592, 611, 690, 439, 768, 645, 795, 611, 333, 863, 333, 658, 500, 500, 631, 549, 549, 494, 439, 521, 411, 603, 329, 603, 549, 549, 576, 521, 549, 549, 521, 549, 603, 439, 576, 713, 686, 493, 686, 494, 480, 200, 480, 549, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 750, 620, 247, 549, 167, 713, 500, 753, 753, 753, 753, 1042, 987, 603, 987, 603, 400, 549, 411, 549, 549, 713, 494, 460, 549, 549, 549, 549, 1000, 603, 1000, 658, 823, 686, 795, 987, 768, 768, 823, 768, 768, 713, 713, 713, 713, 713, 713, 713, 768, 713, 790, 790, 890, 823, 549, 250, 713, 603, 603, 1042, 987, 603, 987, 603, 494, 329, 790, 790, 786, 713, 384, 384, 384, 384, 384, 384, 494, 494, 494, 494, 0, 329, 274, 686, 686, 686, 384, 384, 384, 384, 384, 384, 494, 494, 494, 0],
        
        'zapfdingbats'=>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 278, 974, 961, 974, 980, 719, 789, 790, 791, 690, 960, 939, 549, 855, 911, 933, 911, 945, 974, 755, 846, 762, 761, 571, 677, 763, 760, 759, 754, 494, 552, 537, 577, 692, 786, 788, 788, 790, 793, 794, 816, 823, 789, 841, 823, 833, 816, 831, 923, 744, 723, 749, 790, 792, 695, 776, 768, 792, 759, 707, 708, 682, 701, 826, 815, 789, 789, 707, 687, 696, 689, 786, 787, 713, 791, 785, 791, 873, 761, 762, 762, 759, 759, 892, 892, 788, 784, 438, 138, 277, 415, 392, 392, 668, 668, 0, 390, 390, 317, 317, 276, 276, 509, 509, 410, 410, 234, 234, 334, 334, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 732, 544, 544, 910, 667, 760, 760, 776, 595, 694, 626, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 894, 838, 1016, 458, 748, 924, 748, 918, 927, 928, 928, 834, 873, 828, 924, 924, 917, 930, 931, 463, 883, 836, 836, 867, 867, 696, 696, 874, 0, 874, 760, 946, 771, 865, 771, 888, 967, 888, 831, 873, 927, 970, 918, 0]
    }

    def initialize(orientation='P', unit='mm', format='A4')
        # Initialization of properties
        @page=0
        @n=2
        @buffer=''
        @pages=[]
        @OrientationChanges=[]
        @state=0
        @fonts={}
        @FontFiles={}
        @diffs=[]
        @images={}
        @links=[]
        @PageLinks={}
        @InFooter=false
        @FontFamily=''
        @FontStyle=''
        @FontSizePt=12
        @underline= false
        @DrawColor='0 G'
        @FillColor='0 g'
        @TextColor='0 g'
        @ColorFlag=false
        @ws=0
        @offsets=[]

        # Standard fonts
        @CoreFonts={}
        @CoreFonts['courier']='Courier'
        @CoreFonts['courierB']='Courier-Bold'
        @CoreFonts['courierI']='Courier-Oblique'
        @CoreFonts['courierBI']='Courier-BoldOblique'
        @CoreFonts['helvetica']='Helvetica'
        @CoreFonts['helveticaB']='Helvetica-Bold'
        @CoreFonts['helveticaI']='Helvetica-Oblique'
        @CoreFonts['helveticaBI']='Helvetica-BoldOblique'
        @CoreFonts['times']='Times-Roman'
        @CoreFonts['timesB']='Times-Bold'
        @CoreFonts['timesI']='Times-Italic'
        @CoreFonts['timesBI']='Times-BoldItalic'
        @CoreFonts['symbol']='Symbol'
        @CoreFonts['zapfdingbats']='ZapfDingbats'

        # Scale factor
        if unit=='pt'
            @k=1
        elsif unit=='mm'
            @k=72/25.4
        elsif unit=='cm'
            @k=72/2.54;
        elsif unit=='in'
            @k=72
        else
            raise 'Incorrect unit: '+unit
        end

        # Page format
        if format.is_a? String
            format.downcase!
            if format=='a3'
                format=[841.89,1190.55]
            elsif format=='a4'
                format=[595.28,841.89]
            elsif format=='a5'
                format=[420.94,595.28]
            elsif format=='letter'
                format=[612,792]
            elsif format=='legal'
                format=[612,1008]
            else
                raise 'Unknown page format: '+format
            end
            @fwPt,@fhPt=format
        else
            @fwPt=format[0]*@k
            @fhPt=format[1]*@k
        end
        @fw=@fwPt/@k;
        @fh=@fhPt/@k;

        # Page orientation
        orientation.downcase!
        if orientation=='p' or orientation=='portrait'
            @DefOrientation='P'
            @wPt=@fwPt
            @hPt=@fhPt
        elsif orientation=='l' or orientation=='landscape'
            @DefOrientation='L'
            @wPt=@fhPt
            @hPt=@fwPt
        else
            raise 'Incorrect orientation: '+orientation
        end
        @CurOrientation=@DefOrientation
        @w=@wPt/@k
        @h=@hPt/@k

        # Page margins (1 cm)
        margin=28.35/@k
        SetMargins(margin,margin)
        # Interior cell margin (1 mm)
        @cMargin=margin/10
        # Line width (0.2 mm)
        @LineWidth=0.567/@k
        # Automatic page break
        SetAutoPageBreak(true,2*margin)
        # Full width display mode
        SetDisplayMode('fullwidth')
        # Enable compression
        SetCompression(true)
        # Set default PDF version number
        @PDFVersion='1.3'
    end

    def SetMargins(left, top, right=-1)
        # Set left, top and right margins
        @lMargin=left
        @tMargin=top
        right=left if right==-1
        @rMargin=right
    end

    def SetLeftMargin(margin)
        # Set left margin
        @lMargin=margin
        @x=margin if @page>0 and @x<margin
    end

    def SetTopMargin(margin)
        # Set top margin
        @tMargin=margin
    end

    def SetRightMargin(margin)
        #Set right margin
        @rMargin=margin
    end

    def SetAutoPageBreak(auto, margin=0)
        # Set auto page break mode and triggering margin
        @AutoPageBreak=auto
        @bMargin=margin
        @PageBreakTrigger=@h-margin
    end

    def SetDisplayMode(zoom, layout='continuous')
        # Set display mode in viewer
        if zoom=='fullpage' or zoom=='fullwidth' or zoom=='real' or
            zoom=='default' or not zoom.kind_of? String

            @ZoomMode=zoom;
        elsif zoom=='zoom'
            @ZoomMode=layout
        else
            raise 'Incorrect zoom display mode: '+zoom
        end
        if layout=='single' or layout=='continuous' or layout=='two' or
            layout=='default'

            @LayoutMode=layout
        elsif zoom!='zoom'
            raise 'Incorrect layout display mode: '+layout
        end
    end

    def SetCompression(compress)
        # Set page compression
        @compress = compress
    end

    def SetTitle(title)
        # Title of document
        @title=title
    end

    def SetSubject(subject)
        # Subject of document
        @subject=subject
    end

    def SetAuthor(author)
        # Author of document
        @author=author
    end

    def SetKeywords(keywords)
        # Keywords of document
        @keywords=keywords
    end

    def SetCreator(creator)
        # Creator of document
        @creator=creator
    end

    def AliasNbPages(aliasnb='{nb}')
        # Define an alias for total number of pages
        @AliasNbPages=aliasnb
    end
    
    def Error(msg)
        raise 'FPDF error: '+msg
    end

    def Open
        # Begin document
        @state=1
    end

    def Close
        # Terminate document
        return if @state==3
        self.AddPage if @page==0
        # Page footer
        @InFooter=true
        self.Footer
        @InFooter=false
        # Close page
        endpage
        # Close document
        enddoc
    end

    def AddPage(orientation='')
        # Start a new page
        self.Open if @state==0
        family=@FontFamily
        style=@FontStyle+(@underline ? 'U' : '')
        size=@FontSizePt
        lw=@LineWidth
        dc=@DrawColor
        fc=@FillColor
        tc=@TextColor
        cf=@ColorFlag
        if @page>0
            # Page footer
            @InFooter=true
            self.Footer
            @InFooter=false
            # Close page
            endpage
        end
        # Start new page
        beginpage(orientation)
        # Set line cap style to square
        out('2 J')
        # Set line width
        @LineWidth=lw
        out(sprintf('%.2f w',lw*@k))
        # Set font
        SetFont(family,style,size) if family
        # Set colors
        @DrawColor=dc
        out(dc) if dc!='0 G'
        @FillColor=fc
        out(fc) if fc!='0 g'
        @TextColor=tc
        @ColorFlag=cf
        # Page header
        self.Header
        # Restore line width
        if @LineWidth!=lw
            @LineWidth=lw
            out(sprintf('%.2f w',lw*@k))
        end
        # Restore font
        self.SetFont(family,style,size) if family
        # Restore colors
        if @DrawColor!=dc
            @DrawColor=dc
            out(dc)
        end
        if @FillColor!=fc
            @FillColor=fc
            out(fc)
        end
        @TextColor=tc
        @ColorFlag=cf
    end

    def Header
        # To be implemented in your inherited class
    end

    def Footer
        # To be implemented in your inherited class
    end

    def PageNo
        # Get current page number
        @page
    end

    def SetDrawColor(r,g=-1,b=-1)
        # Set color for all stroking operations
        if (r==0 and g==0 and b==0) or g==-1
            @DrawColor=sprintf('%.3f G',r/255.0)
        else
            @DrawColor=sprintf('%.3f %.3f %.3f RG',r/255.0,g/255.0,b/255.0)
        end
        out(@DrawColor) if(@page>0)
    end

    def SetFillColor(r,g=-1,b=-1)
        # Set color for all filling operations
        if (r==0 and g==0 and b==0) or g==-1
            @FillColor=sprintf('%.3f g',r/255.0)
        else
            @FillColor=sprintf('%.3f %.3f %.3f rg',r/255.0,g/255.0,b/255.0)
        end
        @ColorFlag=(@FillColor!=@TextColor)
        out(@FillColor) if(@page>0)
    end

    def SetTextColor(r,g=-1,b=-1)
        # Set color for text
        if (r==0 and g==0 and b==0) or g==-1
            @TextColor=sprintf('%.3f g',r/255.0)
        else
            @TextColor=sprintf('%.3f %.3f %.3f rg',r/255.0,g/255.0,b/255.0)
        end
        @ColorFlag=(@FillColor!=@TextColor)
    end
    
    def GetCharWidth(widths, index)
      if index.is_a?(String)
        widths[index.ord]
      else
        widths[index]
      end
    end

    def GetStringWidth(s)
        # Get width of a string in the current font
        cw=@CurrentFont['cw']
        w=0
        s.each_byte do |c|
            w=w+GetCharWidth(cw, c)
        end
        w*@FontSize/1000.0
    end

    def SetLineWidth(width)
        # Set line width
        @LineWidth=width
        out(sprintf('%.2f w',width*@k)) if @page>0
    end

    def Line(x1, y1, x2, y2)
        # Draw a line
        out(sprintf('%.2f %.2f m %.2f %.2f l S',
            x1*@k,(@h-y1)*@k,x2*@k,(@h-y2)*@k))
    end

    def Rect(x, y, w, h, style='')
        # Draw a rectangle
        if style=='F'
            op='f'
        elsif style=='FD' or style=='DF'
            op='B'
        else
            op='S'
        end
        out(sprintf('%.2f %.2f %.2f %.2f re %s', x*@k,(@h-y)*@k,w*@k,-h*@k,op))
    end

    def AddFont(family, style='', file='')
         # Add a TrueType or Type1 font
         family = family.downcase
         family = 'helvetica' if family == 'arial'

         style = style.upcase
         style = 'BI' if style == 'IB'

        fontkey = family + style

        if @fonts.has_key?(fontkey)
             self.Error("Font already added: #{family} #{style}")
        end

        file = family.gsub(' ', '') + style.downcase + '.rb' if file == ''

        if self.class.const_defined? 'FPDF_FONTPATH'
            if FPDF_FONTPATH[-1,1] == '/'
                file = FPDF_FONTPATH + file
            else
                file = FPDF_FONTPATH + '/' + file
            end
        end
        
        # Changed from "require file" to fix bug reported by Hans Allis.
        load file

        if FontDef.desc.nil?
           self.Error("Could not include font definition file #{file}")
        end

        i = @fonts.length + 1

        @fonts[fontkey] = {'i'   => i,
                          'type' => FontDef.type,
                          'name' => FontDef.name,
                          'desc' => FontDef.desc,
                            'up' => FontDef.up,
                            'ut' => FontDef.ut,
                            'cw' => FontDef.cw,
                           'enc' => FontDef.enc,
                          'file' => FontDef.file
                       }

        if FontDef.diff
            # Search existing encodings
            unless @diffs.include?(FontDef.diff)
                @diffs.push(FontDef.diff)
                @fonts[fontkey]['diff'] = @diffs.length - 1
            end
        end

        if FontDef.file
             if FontDef.type == 'TrueType'
                 @FontFiles[FontDef.file] = {'length1' => FontDef.originalsize}
             else
                 @FontFiles[FontDef.file] = {'length1' => FontDef.size1, 'length2' => FontDef.size2}
            end
        end

        return self
    end

    def SetFont(family, style='', size=0)
        # Select a font; size given in points
        family.downcase!
        family=@FontFamily if family==''
        if family=='arial'
            family='helvetica'
        elsif family=='symbol' or family=='zapfdingbats'
            style=''
        end
        style.upcase!
        unless style.index('U').nil?
            @underline=true
            style.gsub!('U','')
        else
            @underline=false;
        end
        style='BI' if style=='IB'
        size=@FontSizePt if size==0
        # Test if font is already selected
        return if @FontFamily==family and
            @FontStyle==style and @FontSizePt==size
        # Test if used for the first time
        fontkey=family+style
        unless @fonts.has_key?(fontkey)
            if @CoreFonts.has_key?(fontkey)
                unless Charwidths.has_key?(fontkey)
                    raise 'Font unavailable'
                end
                @fonts[fontkey]={
                    'i'=>@fonts.size,
                    'type'=>'core',
                    'name'=>@CoreFonts[fontkey],
                    'up'=>-100,
                    'ut'=>50,
                    'cw'=>Charwidths[fontkey]}
            else
                raise 'Font unavailable'
            end
        end

        #Select it
        @FontFamily=family
        @FontStyle=style;
        @FontSizePt=size
        @FontSize=size/@k;
        @CurrentFont=@fonts[fontkey]
        if @page>0
            out(sprintf('BT /F%d %.2f Tf ET', @CurrentFont['i'], @FontSizePt))
        end
    end

    def SetFontSize(size)
        # Set font size in points
        return if @FontSizePt==size
        @FontSizePt=size
        @FontSize=size/@k
        if @page>0
            out(sprintf('BT /F%d %.2f Tf ET',@CurrentFont['i'],@FontSizePt))
        end
    end

    def AddLink
        # Create a new internal link
        @links.push([0, 0])
        @links.size
    end

    def SetLink(link, y=0, page=-1)
        # Set destination of internal link
        y=@y if y==-1
        page=@page if page==-1
        @links[link]=[page, y]
    end

    def Link(x, y, w, h, link)
        # Put a link on the page
        @PageLinks[@page]=Array.new unless @PageLinks.has_key?(@Page)
        @PageLinks[@page].push([x*@k,@hPt-y*@k,w*@k,h*@k,link])
    end

    def Text(x, y, txt)
        # Output a string
        txt.gsub!(')', '\\)')
        txt.gsub!('(', '\\(')
        txt.gsub!('\\', '\\\\')
        s=sprintf('BT %.2f %.2f Td (%s) Tj ET',x*@k,(@h-y)*@k,txt);
        s=s+' '+dounderline(x,y,txt) if @underline and txt!=''
        s='q '+@TextColor+' '+s+' Q' if @ColorFlag
        out(s)
    end

    def AcceptPageBreak
        # Accept automatic page break or not
        @AutoPageBreak
    end

    def Cell(w,h=0,txt='',border=0,ln=0,align='',fill=0,link='')
        # Output a cell
        if @y+h>@PageBreakTrigger and !@InFooter and self.AcceptPageBreak
            # Automatic page break
            x=@x
            ws=@ws
            if ws>0
                @ws=0
                out('0 Tw')
            end
            self.AddPage(@CurOrientation)
            @x=x
            if ws>0
                @ws=ws
                out(sprintf('%.3f Tw',ws*@k))
            end
        end
        w=@w-@rMargin-@x if w==0
        s=''
        if fill==1 or border==1
            if fill==1
                op=(border==1) ? 'B' : 'f'
            else
                op='S'
            end
            s=sprintf('%.2f %.2f %.2f %.2f re %s ',@x*@k,(@h-@y)*@k,w*@k,-h*@k,op)
        end
        if border.is_a? String
            x=@x
            y=@y
            unless border.index('L').nil?
                s=s+sprintf('%.2f %.2f m %.2f %.2f l S ',
                    x*@k,(@h-y)*@k,x*@k,(@h-(y+h))*@k)
            end
            unless border.index('T').nil?
                s=s+sprintf('%.2f %.2f m %.2f %.2f l S ',
                    x*@k,(@h-y)*@k,(x+w)*@k,(@h-y)*@k)
            end
            unless border.index('R').nil?
                s=s+sprintf('%.2f %.2f m %.2f %.2f l S ',
                    (x+w)*@k,(@h-y)*@k,(x+w)*@k,(@h-(y+h))*@k)
            end
            unless border.index('B').nil?
                s=s+sprintf('%.2f %.2f m %.2f %.2f l S ',
                    x*@k,(@h-(y+h))*@k,(x+w)*@k,(@h-(y+h))*@k)
            end
        end
        if txt!=''
            if align=='R'
                dx=w-@cMargin-self.GetStringWidth(txt)
            elsif align=='C'
                dx=(w-self.GetStringWidth(txt))/2
            else
                dx=@cMargin
            end
            txt = txt.gsub(')', '\\)')
            txt.gsub!('(', '\\(')
            txt.gsub!('\\', '\\\\')
            if @ColorFlag
                s=s+'q '+@TextColor+' '
            end
            s=s+sprintf('BT %.2f %.2f Td (%s) Tj ET',
                (@x+dx)*@k,(@h-(@y+0.5*h+0.3*@FontSize))*@k,txt)
            s=s+' '+dounderline(@x+dx,@y+0.5*h+0.3*@FontSize,txt) if @underline
            s=s+' Q' if @ColorFlag
            if link and link != ''
                Link(@x+dx,@y+0.5*h-0.5*@FontSize,GetStringWidth(txt),@FontSize,link)
            end
        end
        out(s) if s
        @lasth=h
        if ln>0
            # Go to next line
            @y=@y+h
            @x=@lMargin if ln==1
        else
            @x=@x+w
        end
    end

    def MultiCell(w,h,txt,border=0,align='J',fill=0)
        # Output text with automatic or explicit line breaks
        cw=@CurrentFont['cw']
        w=@w-@rMargin-@x if w==0
        wmax=(w-2*@cMargin)*1000/@FontSize
        s=txt.gsub('\r','')
        nb=s.length
        nb=nb-1 if nb>0 and s[nb-1].chr=='\n'
        b=0
        if border!=0
            if border==1
                border='LTRB'
                b='LRT'
                b2='LR'
            else
                b2=''
                b2='L' unless border.index('L').nil?
                b2=b2+'R' unless border.index('R').nil?
                b=(not border.index('T').nil?) ? (b2+'T') : b2
            end
        end
        sep=-1
        i=0
        j=0
        l=0
        ns=0
        nl=1
        while i<nb
            # Get next character
            c=s[i].chr
            if c=="\n"
                # Explicit line break
                if @ws>0
                    @ws=0
                    out('0 Tw')
                end
#Ed Moss               
# Don't let i go negative
                end_i = i == 0 ? 0 : i - 1
                # Changed from s[j..i] to fix bug reported by Hans Allis.
                self.Cell(w,h,s[j..end_i],b,2,align,fill) 
#                
                i=i+1
                sep=-1
                j=i
                l=0
                ns=0
                nl=nl+1
                b=b2 if border and nl==2
            else
                if c==' '
                    sep=i
                    ls=l
                    ns=ns+1
                end
                l=l+GetCharWidth(cw, c[0])
                if l>wmax
                    # Automatic line break
                    if sep==-1
                        i=i+1 if i==j
                        if @ws>0
                            @ws=0
                            out('0 Tw')
                        end
                        self.Cell(w,h,s[j..i],b,2,align,fill)
#Ed Moss
# Added so that it wouldn't print the last character of the string if it got close
#FIXME 2006-07-18 Level=0 - but it still puts out an extra new line
                        i += 1
#
                    else
                        if align=='J'
                            @ws=(ns>1) ? (wmax-ls)/1000.0*@FontSize/(ns-1) : 0
                            out(sprintf('%.3f Tw',@ws*@k))
                        end
                        self.Cell(w,h,s[j..sep],b,2,align,fill)
                        i=sep+1
                    end
                    sep=-1
                    j=i
                    l=0
                    ns=0
                    nl=nl+1
                    b=b2 if border and nl==2
                else
                    i=i+1
                end
            end
        end

        # Last chunk
        if @ws>0
            @ws=0
            out('0 Tw')
        end
        b=b+'B' if border!=0 and not border.index('B').nil?
        self.Cell(w,h,s[j..i],b,2,align,fill)
        @x=@lMargin
    end
    
    def Write(h,txt,link='')
        # Output text in flowing mode
        cw=@CurrentFont['cw']
        w=@w-@rMargin-@x
        wmax=(w-2*@cMargin)*1000/@FontSize
        s=txt.gsub("\r",'')
        nb=s.length
        sep=-1
        i=0
        j=0
        l=0
        nl=1
        while i<nb
            # Get next character
            c=s[i]
            if c=="\n"[0]
                # Explicit line break
                self.Cell(w,h,s[j,i-j],0,2,'',0,link)
                i=i+1
                sep=-1
                j=i
                l=0
                if nl==1
                    @x=@lMargin
                    w=@w-@rMargin-@x
                    wmax=(w-2*@cMargin)*1000/@FontSize
                end
                nl=nl+1
                next
            end
            if c==' '[0]
                sep=i
                ls=l
            end
            l=l+GetCharWidth(cw, c);
            if l>wmax
                # Automatic line break
                if sep==-1
                    if @x>@lMargin
                        # Move to next line
                        @x=@lMargin
                        @y=@y+h
                        w=@w-@rMargin-@x
                        wmax=(w-2*@cMargin)*1000/@FontSize
                        i=i+1
                        nl=nl+1
                        next
                    end
                    i=i+1 if i==j
                    self.Cell(w,h,s[j,i-j],0,2,'',0,link)
                else
                    self.Cell(w,h,s[j,sep-j],0,2,'',0,link)
                    i=sep+1
                end
                sep=-1
                j=i
                l=0
                if nl==1
                    @x=@lMargin
                    w=@w-@rMargin-@x
                    wmax=(w-2*@cMargin)*1000/@FontSize
                end
                nl=nl+1
            else
                i=i+1
            end
        end
        # Last chunk
        self.Cell(l/1000.0*@FontSize,h,s[j,i],0,0,'',0,link) if i!=j
    end
    
    def Image(file,x,y,w=0,h=0,type='',link='')
        # Put an image on the page
        unless @images.has_key?(file)
            # First use of image, get info
            if type==''
                pos=file.rindex('.')
                if pos.nil?
                    self.Error('Image file has no extension and no type was '+
                        'specified: '+file)
                end
                type=file[pos+1..-1]
            end
            type.downcase!
            if type=='jpg' or type=='jpeg'
                info=parsejpg(file)
            elsif type=='png'
                info=parsepng(file)
            else
                self.Error('Unsupported image file type: '+type)
            end
            info['i']=@images.length+1
            @images[file]=info
        else
            info=@images[file]
        end
#Ed Moss
        if(w==0 && h==0)
      		#Put image at 72 dpi
      		w=info['w']/@k;
      		h=info['h']/@k;
      	end
#
        # Automatic width or height calculation
        w=h*info['w']/info['h'] if w==0
        h=w*info['h']/info['w'] if h==0
        out(sprintf('q %.2f 0 0 %.2f %.2f %.2f cm /I%d Do Q',
            w*@k,h*@k,x*@k,(@h-(y+h))*@k,info['i']))
        Link(x,y,w,h,link) if link and link != ''
    end
    
    def Ln(h='')
        # Line feed; default value is last cell height
        @x=@lMargin
        if h.kind_of?(String)
            @y=@y+@lasth
        else
            @y=@y+h
        end
    end

    def GetX
        # Get x position
        @x
    end

    def SetX(x)
        # Set x position
        if x>=0
            @x=x
        else
            @x=@w+x
        end
    end

    def GetY
        # Get y position
        @y
    end

    def SetY(y)
        # Set y position and reset x
        @x=@lMargin
        if y>=0
            @y=y
        else
            @y=@h+y
        end
    end

    def SetXY(x,y)
        # Set x and y positions
        SetY(y)
        SetX(x)
    end
    
    def Output(file=nil)
        # Output PDF to file or return as a string
        
        # Finish document if necessary
        self.Close if(@state<3)
        
        if file.nil?
            # Return as a string
            return @buffer
        else
            # Save file locally
            open(file,'wb') do |f|
                f.write(@buffer)
            end
        end
    end

    private
  
    def putpages
        nb=@page
        unless @AliasNbPages.nil? or @AliasNbPages==''
            # Replace number of pages
            1.upto(nb) do |n|
                @pages[n].gsub!(@AliasNbPages,nb.to_s)
            end
        end
        if @DefOrientation=='P'
            wPt=@fwPt
            hPt=@fhPt
        else
            wPt=@fhPt
            hPt=@fwPt
        end
        filter=(@compress) ? '/Filter /FlateDecode ' : ''
        1.upto(nb) do |n|
            # Page
            newobj
            out('<</Type /Page')
            out('/Parent 1 0 R')
            unless @OrientationChanges[n].nil?
                out(sprintf('/MediaBox [0 0 %.2f %.2f]',hPt,wPt))
            end
            out('/Resources 2 0 R')
            if @PageLinks[n]
                # Links
                annots='/Annots ['
                @PageLinks[n].each do |pl|
                    rect=sprintf('%.2f %.2f %.2f %.2f',
                        pl[0],pl[1],pl[0]+pl[2],pl[1]-pl[3])
                    annots=annots+'<</Type /Annot /Subtype /Link /Rect ['+rect+
                        '] /Border [0 0 0] '
                    if pl[4].kind_of?(String)
                        annots=annots+'/A <</S /URI /URI '+textstring(pl[4])+
                            '>>>>'
                    else
                        l=@links[pl[4]]
                        h=@OrientationChanges[l[0]].nil? ? hPt : wPt
                        annots=annots+sprintf(
                            '/Dest [%d 0 R /XYZ 0 %.2f null]>>',
                            1+2*l[0],h-l[1]*@k)
                    end
                end
                out(annots+']')
            end
            out('/Contents '+(@n+1).to_s+' 0 R>>')
            out('endobj')
            # Page content
            p=(@compress) ? Zlib::Deflate.deflate(@pages[n]) : @pages[n]
            newobj
            out('<<'+filter+'/Length '+p.length.to_s+'>>')
            putstream(p)
            out('endobj')
        end
        # Pages root
        @offsets[1]=@buffer.length
        out('1 0 obj')
        out('<</Type /Pages')
        kids='/Kids ['
        nb.times do |i|
            kids=kids+(3+2*i).to_s+' 0 R '
        end
        out(kids+']')
        out('/Count '+nb.to_s)
        out(sprintf('/MediaBox [0 0 %.2f %.2f]',wPt,hPt))
        out('>>')
        out('endobj')
    end
    
    def putfonts
        nf=@n
        @diffs.each do |diff|
            # Encodings
            newobj
            out('<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences '+
                '['+diff+']>>')
            out('endobj')
        end

        @FontFiles.each do |file, info|
            # Font file embedding
            newobj
            @FontFiles[file]['n'] = @n

            if self.class.const_defined? 'FPDF_FONTPATH' then
                if FPDF_FONTPATH[-1,1] == '/' then
                    file = FPDF_FONTPATH + file
                else
                    file = FPDF_FONTPATH + '/' + file
                end
            end

            size = File.size(file)
            unless File.exists?(file)
                Error('Font file not found')
            end

            out('<</Length ' + size.to_s)

            if file[-2, 2] == '.z' then
                out('/Filter /FlateDecode')
            end
            out('/Length1 ' + info['length1'])
            out('/Length2 ' + info['length2'] + ' /Length3 0') if info['length2']
            out('>>')
            open(file, 'rb') do |f|
                putstream(f.read())
            end
            out('endobj')
        end

        file = 0
        @fonts.each do |k, font|
            # Font objects
            @fonts[k]['n']=@n+1
            type=font['type']
            name=font['name']
            if type=='core'
                # Standard font
                newobj
                out('<</Type /Font')
                out('/BaseFont /'+name)
                out('/Subtype /Type1')
                if name!='Symbol' and name!='ZapfDingbats'
                    out('/Encoding /WinAnsiEncoding')
                end
                out('>>')
                out('endobj')
            elsif type=='Type1' or type=='TrueType'
                # Additional Type1 or TrueType font
                newobj
                out('<</Type /Font')
                out('/BaseFont /'+name)
                out('/Subtype /'+type)
                out('/FirstChar 32 /LastChar 255')
                out('/Widths '+(@n+1).to_s+' 0 R')
                out('/FontDescriptor '+(@n+2).to_s+' 0 R')
                if font['enc'] and font['enc'] != ''
                    unless font['diff'].nil?
                        out('/Encoding '+(nf+font['diff']).to_s+' 0 R')
                    else
                        out('/Encoding /WinAnsiEncoding')
                    end
                end
                out('>>')
                out('endobj')
                # Widths
                newobj
                cw=font['cw']
                s='['
                32.upto(255) do |i|
                    s << GetCharWidth(cw, i).to_s + ' '
                end
                out(s+']')
                out('endobj')
                # Descriptor
                newobj
                s='<</Type /FontDescriptor /FontName /'+name
                font['desc'].each do |k, v|
                    s << ' /'+k+' '+v
                end
                file=font['file']
                if file
                    s << ' /FontFile'+(type=='Type1' ? '' : '2')+' '+
                        @FontFiles[file]['n'].to_s+' 0 R'
                end
                out(s+'>>')
                out('endobj')
            else
                # Allow for additional types
                mtd='put'+type.downcase
                unless self.respond_to?(mtd)
                    self.Error('Unsupported font type: '+type)
                end
                self.send(mtd, font)
            end
        end
    end
    
    def putimages
        filter=(@compress) ? '/Filter /FlateDecode ' : ''
        @images.each do |file, info|
            newobj
            @images[file]['n']=@n
            out('<</Type /XObject')
            out('/Subtype /Image')
            out('/Width '+info['w'].to_s)
            out('/Height '+info['h'].to_s)
            if info['cs']=='Indexed'
                out("/ColorSpace [/Indexed /DeviceRGB #{info['pal'].length/3-1} #{(@n+1)} 0 R]")
            else
                out('/ColorSpace /'+info['cs'])
                if info['cs']=='DeviceCMYK'
                    out('/Decode [1 0 1 0 1 0 1 0]')
                end
            end
            out('/BitsPerComponent '+info['bpc'].to_s)
            out('/Filter /'+info['f']) if info['f']
            unless info['parms'].nil?
                out(info['parms'])
            end
            if info['trns'] and info['trns'].kind_of?(Array)
                trns=''
                info['trns'].length.times do |i|
                    trns=trns+info['trns'][i].to_s+' '+info['trns'][i].to_s+' '
                end
                out('/Mask ['+trns+']')
            end
            out('/Length '+info['data'].length.to_s+'>>')
            putstream(info['data'])
            @images[file]['data']=nil
            out('endobj')
            # Palette
            if info['cs']=='Indexed'
                newobj
                pal=(@compress) ? Zlib::Deflate.deflate(info['pal']) : info['pal']
                out('<<'+filter+'/Length '+pal.length.to_s+'>>')
                putstream(pal)
                out('endobj')
            end
        end
    end

    def putxobjectdict
        @images.each_value do |image|
            out('/I'+image['i'].to_s+' '+image['n'].to_s+' 0 R')
        end
    end

    def putresourcedict
        out('/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]')
        out('/Font <<')
        @fonts.each_value do |font|
            out('/F'+font['i'].to_s+' '+font['n'].to_s+' 0 R')
        end
        out('>>')
        out('/XObject <<')
        putxobjectdict
        out('>>')
    end

    def putresources
        putfonts
        putimages
        # Resource dictionary
        @offsets[2]=@buffer.length
        out('2 0 obj')
        out('<<')
        putresourcedict
        out('>>')
        out('endobj')
    end
    
    def putinfo
        out('/Producer '+textstring('Ruby FPDF '+FPDF_VERSION));
        unless @title.nil?
            out('/Title '+textstring(@title))
        end
        unless @subject.nil?
            out('/Subject '+textstring(@subject))
        end
        unless @author.nil?
            out('/Author '+textstring(@author))
        end
        unless @keywords.nil?
            out('/Keywords '+textstring(@keywords))
        end
        unless @creator.nil?
            out('/Creator '+textstring(@creator))
        end
        out('/CreationDate '+textstring('D: '+DateTime.now.to_s))
    end
    
    def putcatalog
        out('/Type /Catalog')
        out('/Pages 1 0 R')
        if @ZoomMode=='fullpage'
            out('/OpenAction [3 0 R /Fit]')
        elsif @ZoomMode=='fullwidth'
            out('/OpenAction [3 0 R /FitH null]')
        elsif @ZoomMode=='real'
            out('/OpenAction [3 0 R /XYZ null null 1]')
        elsif not @ZoomMode.kind_of?(String)
            out('/OpenAction [3 0 R /XYZ null null '+(@ZoomMode/100)+']')
        end
        
        if @LayoutMode=='single'
            out('/PageLayout /SinglePage')
        elsif @LayoutMode=='continuous'
            out('/PageLayout /OneColumn')
        elsif @LayoutMode=='two'
            out('/PageLayout /TwoColumnLeft')
        end
    end

    def putheader
        out('%PDF-'+@PDFVersion)
    end

    def puttrailer
        out('/Size '+(@n+1).to_s)
        out('/Root '+@n.to_s+' 0 R')
        out('/Info '+(@n-1).to_s+' 0 R')
    end

    def enddoc
        putheader
        putpages
        putresources
        # Info
        newobj
        out('<<')
        putinfo
        out('>>')
        out('endobj')
        # Catalog
        newobj
        out('<<')
        putcatalog
        out('>>')
        out('endobj')
        # Cross-ref
        o=@buffer.length
        out('xref')
        out('0 '+(@n+1).to_s)
        out('0000000000 65535 f ')
        1.upto(@n) do |i|
            out(sprintf('%010d 00000 n ',@offsets[i]))
        end
        # Trailer
        out('trailer')
        out('<<')
        puttrailer
        out('>>')
        out('startxref')
        out(o)
        out('%%EOF')
        state=3
    end

    def beginpage(orientation)
        @page=@page+1
        @pages[@page]=''
        @state=2
        @x=@lMargin
        @y=@tMargin
        @lasth=0
        @FontFamily=''
        # Page orientation
        if orientation==''
            orientation=@DefOrientation
        else
            orientation=orientation[0].chr.upcase
            if orientation!=@DefOrientation
                @OrientationChanges[@page]=true
            end
        end
        if orientation!=@CurOrientation
            # Change orientation
            if orientation=='P'
                @wPt=@fwPt
                @hPt=@fhPt
                @w=@fw
                @h=@fh
            else
                @wPt=@fhPt
                @hPt=@fwPt
                @w=@fh
                @h=@fw
            end
            @PageBreakTrigger=@h-@bMargin
            @CurOrientation=orientation
        end
    end
    
    def endpage
        # End of page contents
        @state=1
    end
    
    def newobj
        # Begin a new object
        @n=@n+1
        @offsets[@n]=@buffer.length
        out(@n.to_s+' 0 obj')
    end

    def dounderline(x,y,txt)
        # Underline text
        up=@CurrentFont['up']
        ut=@CurrentFont['ut']
        w=GetStringWidth(txt)+@ws*txt.count(' ')
        sprintf('%.2f %.2f %.2f %.2f re f',
            x*@k,(@h-(y-up/1000.0*@FontSize))*@k,w*@k,-ut/1000.0*@FontSizePt)
    end
    
    def parsejpg(file)
        # Extract info from a JPEG file
        a=extractjpginfo(file)
        raise "Missing or incorrect JPEG file: #{file}" if a.nil?

        if a['channels'].nil? || a['channels']==3 then
            colspace='DeviceRGB'
        elsif a['channels']==4 then
            colspace='DeviceCMYK'
        else
            colspace='DeviceGray'
        end
        bpc= a['bits'] ? a['bits'].to_i : 8

        # Read whole file
        data = nil
        open(file, 'rb') do |f|
            data = f.read
        end
        return {'w'=>a['width'],'h'=>a['height'],'cs'=>colspace,'bpc'=>bpc,'f'=>'DCTDecode','data'=>data}
    end

    def parsepng(file)
        # Extract info from a PNG file
        f=open(file,'rb')
        # Check signature
        unless f.read(8)==137.chr+'PNG'+13.chr+10.chr+26.chr+10.chr
            self.Error('Not a PNG file: '+file)
        end
        # Read header chunk
        f.read(4)
        if f.read(4)!='IHDR'
            self.Error('Incorrect PNG file: '+file)
        end
        w=freadint(f)
        h=freadint(f)
        bpc=f.read(1)[0]
        if bpc>8
            self.Error('16-bit depth not supported: '+file)
        end
        ct=f.read(1)[0]
        if ct==0
            colspace='DeviceGray'
        elsif ct==2
            colspace='DeviceRGB'
        elsif ct==3
            colspace='Indexed'
        else
            self.Error('Alpha channel not supported: '+file)
        end
        if f.read(1)[0]!=0
            self.Error('Unknown compression method: '+file)
        end
        if f.read(1)[0]!=0
            self.Error('Unknown filter method: '+file)
        end
        if f.read(1)[0]!=0
            self.Error('Interlacing not supported: '+file)
        end
        f.read(4)
        parms='/DecodeParms <</Predictor 15 /Colors '+(ct==2 ? '3' : '1')+
            ' /BitsPerComponent '+bpc.to_s+' /Columns '+w.to_s+'>>'
        # Scan chunks looking for palette, transparency and image data
        pal=''
        trns=''
        data=''
        begin
            n=freadint(f)
            type=f.read(4)
            if type=='PLTE'
                # Read palette
                pal=f.read(n)
                f.read(4)
            elsif type=='tRNS'
                # Read transparency info
                t=f.read(n)
                if ct==0
                    trns=[t[1]]
                elsif ct==2
                    trns=[t[1],t[3],t[5]]
                else
                    pos=t.index(0)
                    trns=[pos] unless pos.nil?
                end
                f.read(4)
            elsif type=='IDAT'
                # Read image data block
                data << f.read(n)
                f.read(4)
            elsif type=='IEND'
                break
            else
                f.read(n+4)
            end
        end while n
        if colspace=='Indexed' and pal==''
            self.Error('Missing palette in '+file)
        end
        f.close
        {'w'=>w,'h'=>h,'cs'=>colspace,'bpc'=>bpc,'f'=>'FlateDecode',
            'parms'=>parms,'pal'=>pal,'trns'=>trns,'data'=>data}
    end

    def freadint(f)
        # Read a 4-byte integer from file
        a = f.read(4).unpack('N')
        return a[0]
    end

    def freadshort(f)
        a = f.read(2).unpack('n')
        return a[0]
    end

    def freadbyte(f)
        a = f.read(1).unpack('C')
        return a[0]
    end

    def textstring(s)
        # Format a text string
        '('+escape(s)+')'
    end

    def escape(s)
        # Add \ before \, ( and )
        s.gsub('\\','\\\\').gsub('(','\\(').gsub(')','\\)')
    end

    def putstream(s)
        out('stream')
        out(s)
        out('endstream')
    end

    def out(s)
        # Add a line to the document
        if @state==2
            @pages[@page]=@pages[@page]+s+"\n"
        else
            @buffer=@buffer+s.to_s+"\n"
        end
    end

    # jpeg marker codes

    M_SOF0  = 0xc0
    M_SOF1  = 0xc1
    M_SOF2  = 0xc2
    M_SOF3  = 0xc3

    M_SOF5  = 0xc5
    M_SOF6  = 0xc6
    M_SOF7  = 0xc7

    M_SOF9  = 0xc9
    M_SOF10 = 0xca
    M_SOF11 = 0xcb

    M_SOF13 = 0xcd
    M_SOF14 = 0xce
    M_SOF15 = 0xcf

    M_SOI   = 0xd8
    M_EOI   = 0xd9
    M_SOS   = 0xda

    def extractjpginfo(file)
        result = nil

        open(file, "rb") do |f|
            marker = jpegnextmarker(f)

            if marker != M_SOI
                return nil
            end

            while true
                marker = jpegnextmarker(f)

                case marker
                  when M_SOF0,  M_SOF1,  M_SOF2,  M_SOF3,
                       M_SOF5,  M_SOF6,  M_SOF7,  M_SOF9,
                     M_SOF10, M_SOF11, M_SOF13, M_SOF14,
                     M_SOF15 then

                    length = freadshort(f)

                    if result.nil?
                        result = {}

                        result['bits']     = freadbyte(f)
                        result['height']   = freadshort(f)
                        result['width']    = freadshort(f)
                        result['channels'] = freadbyte(f)

                        f.seek(length - 8, IO::SEEK_CUR)
                    else
                        f.seek(length - 2, IO::SEEK_CUR)
                    end
                when M_SOS, M_EOI then
                    return result
                else
                    length = freadshort(f)
                    f.seek(length - 2, IO::SEEK_CUR)
                end
            end
        end
    end

    def jpegnextmarker(f)
        while true
            # look for 0xff
            while (c = freadbyte(f)) != 0xff
            end

            c = freadbyte(f)

            if c != 0
                return c
            end
        end
    end
end
