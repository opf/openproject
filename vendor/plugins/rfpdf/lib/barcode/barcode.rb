#-- encoding: UTF-8

#============================================================+
# File name   : barcode.rb
# Begin       : 2002-07-31
# Last Update : 2005-01-02
# Author      : Karim Mribti [barcode@mribti.com]
# Version     : 1.1 [0.0.8a (original code)]
# License     : GNU LGPL (Lesser General Public License) 2.1
#               http://www.gnu.org/copyleft/lesser.txt
# Source Code : http://www.mribti.com/barcode/
#
# Description : Generic Barcode Render Class for PHP using
#               the GD graphics library.
#
# NOTE:
# This version contains changes by Nicola Asuni:
#  - porting to Ruby
#  - code style and formatting
#  - automatic php documentation in PhpDocumentor Style
#    (www.phpdoc.org)
#  - minor bug fixing
#  - $mCharSet and $mChars variables were added here
#============================================================+

#
# Barcode Render Class for PHP using the GD graphics library.
# @author Karim Mribti, Nicola Asuni
# @name BarcodeObject
# @package com.tecnick.tcpdf
# @@version 0.0.8a 2001-04-01 (original code)
# @since 2001-03-25
# @license http://www.gnu.org/copyleft/lesser.html LGPL
#

# Styles
# Global

#
# option: generate barcode border
#
define("BCS_BORDER", 1);

#
# option: use transparent background
#
define("BCS_TRANSPARENT", 2);

#
# option: center barcode
#
define("BCS_ALIGN_CENTER", 4);

#
# option: align left
#
define("BCS_ALIGN_LEFT", 8);

#
# option: align right
#
define("BCS_ALIGN_RIGHT", 16);

#
# option: generate JPEG image
#
define("BCS_IMAGE_JPEG", 32);

#
# option: generate PNG image
#
define("BCS_IMAGE_PNG", 64);

#
# option: draw text
#
define("BCS_DRAW_TEXT", 128);

#
# option: stretch text
#
define("BCS_STRETCH_TEXT", 256);

#
# option: reverse color
#
define("BCS_REVERSE_COLOR", 512);

#
# option: draw check
# (only for I25 code)
#
define("BCS_I25_DRAW_CHECK", 2048);

#
# set default background color
#
define("BCD_DEFAULT_BACKGROUND_COLOR", 0xFFFFFF);

#
# set default foreground color
#
define("BCD_DEFAULT_FOREGROUND_COLOR", 0x000000);

#
# set default style options
#
define("BCD_DEFAULT_STYLE", BCS_BORDER | BCS_ALIGN_CENTER | BCS_IMAGE_PNG);

#
# set default width
#
define("BCD_DEFAULT_WIDTH", 460);

#
# set default height
#
define("BCD_DEFAULT_HEIGHT", 120);

#
# set default font
#
define("BCD_DEFAULT_FONT", 5);

#
# st default horizontal resolution
#
define("BCD_DEFAULT_XRES", 2);

# Margins

#
# set default margin
#
define("BCD_DEFAULT_MAR_Y1", 0);

#
# set default margin
#
define("BCD_DEFAULT_MAR_Y2", 0);

#
# set default text offset
#
define("BCD_DEFAULT_TEXT_OFFSET", 2);

# For the I25 Only

#
# narrow bar option
# (only for I25 code)
#
define("BCD_I25_NARROW_BAR", 1);

#
# wide bar option
# (only for I25 code)
#
define("BCD_I25_WIDE_BAR", 2);

# For the C39 Only

#
# narrow bar option
# (only for c39 code)
#
define("BCD_C39_NARROW_BAR", 1);

#
# wide bar option
# (only for c39 code)
#
define("BCD_C39_WIDE_BAR", 2);

# For Code 128

#
# set type 1 bar
# (only for c128 code)
#
define("BCD_C128_BAR_1", 1);

#
# set type 2 bar
# (only for c128 code)
#
define("BCD_C128_BAR_2", 2);

#
# set type 3 bar
# (only for c128 code)
#
define("BCD_C128_BAR_3", 3);

#
# set type 4 bar
# (only for c128 code)
#
define("BCD_C128_BAR_4", 4);

#
# Barcode Render Class for PHP using the GD graphics library.
# @author Karim Mribti, Nicola Asuni
# @name BarcodeObject
# @package com.tecnick.tcpdf
# @@version 0.0.8a 2001-04-01 (original code)
# @since 2001-03-25
# @license http://www.gnu.org/copyleft/lesser.html LGPL
#
class BarcodeObject {
	#
	# @var Image width in pixels.
	# @access protected
	#
	protected $mWidth;
	
	#
	# @var Image height in pixels.
	# @access protected
	#
	protected $mHeight;
	
	#
	# @var Numeric code for Barcode style.
	# @access protected
	#
	protected $mStyle;
	
	#
	# @var Background color.
	# @access protected
	#
	protected $mBgcolor;
	
	#
	# @var Brush color.
	# @access protected
	#
	protected $mBrush;
	
	#
	# @var Image object.
	# @access protected
	#
	protected $mImg;
	
	#
	# @var Numeric code for character font.
	# @access protected
	#
	protected $mFont;
	
	#
	# @var Error message.
	# @access protected
	#
	protected $mError;
	
	#
	# @var Character Set.
	# @access protected
	#
	protected $mCharSet;
	
	#
	# @var Allowed symbols.
	# @access protected
	#
	protected $mChars;

	#
	# Class Constructor.
	# @param int $Width Image width in pixels.
	# @param int $Height Image height in pixels. 
	# @param int $Style Barcode style.
	#
	def __construct($Width=BCD_DEFAULT_WIDTH, $Height=BCD_DEFAULT_HEIGHT, $Style=BCD_DEFAULT_STYLE)
		@mWidth = $Width;
		@mHeight = $Height;
		@mStyle = $Style;
		@mFont = BCD_DEFAULT_FONT;
		@mImg = ImageCreate(@mWidth, @mHeight);
		$dbColor = @mStyle & BCS_REVERSE_COLOR ? BCD_DEFAULT_FOREGROUND_COLOR : BCD_DEFAULT_BACKGROUND_COLOR;
		$dfColor = @mStyle & BCS_REVERSE_COLOR ? BCD_DEFAULT_BACKGROUND_COLOR : BCD_DEFAULT_FOREGROUND_COLOR;
		@mBgcolor = ImageColorAllocate(@mImg, ($dbColor & 0xFF0000) >> 16,
		($dbColor & 0x00FF00) >> 8, $dbColor & 0x0000FF);
		@mBrush = ImageColorAllocate(@mImg, ($dfColor & 0xFF0000) >> 16,
		($dfColor & 0x00FF00) >> 8, $dfColor & 0x0000FF);
		if (!(@mStyle & BCS_TRANSPARENT))
			ImageFill(@mImg, @mWidth, @mHeight, @mBgcolor);
		end
	end
	
	#
	# Class Destructor.
	# Destroy image object.
	#
	def __destructor()
		@DestroyObject();
	end

	#
	# Returns the image object.
	# @return object image.
	# @author Nicola Asuni
	# @since 1.5.2
	#
	def getImage()
		return @mImg;
	end
	
	#
	# Abstract method used to draw the barcode image.
	# @param int $xres Horizontal resolution.
	#
	def DrawObject($xres)	{
		# there is not implementation neded, is simply the asbsract function.#
		return false;
	end
	
	#
	# Draws the barcode border.
	# @access protected
	#
	protected function DrawBorder()
		ImageRectangle(@mImg, 0, 0, @mWidth-1, @mHeight-1, @mBrush);
	end
	
	#
	# Draws the alphanumeric code.
	# @param int $Font Font type.
	# @param int $xPos Horiziontal position.
	# @param int $yPos Vertical position.
	# @param int $Char Alphanumeric code to write.
	# @access protected
	#
	protected function DrawChar($Font, $xPos, $yPos, $Char)
		ImageString(@mImg,$Font,$xPos,$yPos,$Char,@mBrush);
	end
	
	#
	# Draws a character string.
	# @param int $Font Font type.
	# @param int $xPos Horiziontal position.
	# @param int $yPos Vertical position.
	# @param int $Char string to write.
	# @access protected
	#
	protected function DrawText($Font, $xPos, $yPos, $Char)
		ImageString(@mImg,$Font,$xPos,$yPos,$Char,@mBrush);
	end

	#
	# Draws a single barcode bar.
	# @param int $xPos Horiziontal position.
	# @param int $yPos Vertical position.
	# @param int $xSize Horizontal size.
    # @param int $xSize Vertical size.
    # @return bool trur in case of success, false otherwise.
    # @access protected
	#
	protected function DrawSingleBar($xPos, $yPos, $xSize, $ySize)
		if ($xPos>=0 && $xPos<=@mWidth && ($xPos+$xSize)<=@mWidth &&
		$yPos>=0 && $yPos<=@mHeight && ($yPos+$ySize)<=@mHeight)
			for ($i=0;$i<$xSize;$i++)
				ImageLine(@mImg, $xPos+$i, $yPos, $xPos+$i, $yPos+$ySize, @mBrush);
			end
			return true;
		end
		return false;
	end
	
	#
	# Returns the current error message.
	# @return string error message.
	#
	def GetError()
		return @mError;
	end
	
	#
	# Returns the font height.
	# @param int $font font type.
	# @return int font height.
	#
	def GetFontHeight($font)
		return ImageFontHeight($font);
	end
	
	#
	# Returns the font width.
	# @param int $font font type.
	# @return int font width.
	#
	def GetFontWidth($font)
		return ImageFontWidth($font);
	end
	
	#
	# Set font type.
	# @param int $font font type.
	#
	def SetFont($font)
		@mFont = $font;
	end
	
	#
	# Returns barcode style.
	# @return int barcode style.
	#
	def GetStyle()
		return @mStyle;
	end

	#
	# Set barcode style.
	# @param int $Style barcode style.
	#
	def SetStyle ($Style)
		@mStyle = $Style;
	end

	#
	# Flush the barcode image.
	#
	def FlushObject()
		if ((@mStyle & BCS_BORDER))
			@DrawBorder();
		end
		if (@mStyle & BCS_IMAGE_PNG)
			Header("Content-Type: image/png");
			ImagePng(@mImg);
		elsif (@mStyle & BCS_IMAGE_JPEG)
			Header("Content-Type: image/jpeg");
			ImageJpeg(@mImg);
		end
	end
	
	#
	# Destroy the barcode image.
	#
	def DestroyObject()
		ImageDestroy(@mImg);
	end
}

#============================================================+
# END OF FILE
#============================================================+
