
#============================================================+
# File name   : i25aobject.rb
# Begin       : 2002-07-31
# Last Update : 2004-12-29
# Author      : Karim Mribti [barcode@mribti.com]
#             : Nicola Asuni [info@tecnick.com]
# Version     : 0.0.8a  2001-04-01 (original code)
# License     : GNU LGPL (Lesser General Public License) 2.1
#               http://www.gnu.org/copyleft/lesser.txt
# Source Code : http://www.mribti.com/barcode/
#
# Description : I25 Barcode Render Class for PHP using
#               the GD graphics library.
#               Interleaved 2 of 5 is a numeric only bar code
#               with a optional check number.
#
# NOTE:
# This version contains changes by Nicola Asuni:
#  - porting to Ruby
#  - code style and formatting
#  - automatic php documentation in PhpDocumentor Style
#    (www.phpdoc.org)
#  - minor bug fixing
#============================================================+

#
# I25 Barcode Render Class for PHP using the GD graphics library.<br<
# Interleaved 2 of 5 is a numeric only bar code with a optional check number.
# @author Karim Mribti, Nicola Asuni
# @name BarcodeObject
# @package com.tecnick.tcpdf
# @@version 0.0.8a  2001-04-01 (original code)
# @since 2001-03-25
# @license http://www.gnu.org/copyleft/lesser.html LGPL
#

#
# I25 Barcode Render Class for PHP using the GD graphics library.<br<
# Interleaved 2 of 5 is a numeric only bar code with a optional check number.
# @author Karim Mribti, Nicola Asuni
# @name BarcodeObject
# @package com.tecnick.tcpdf
# @@version 0.0.8a  2001-04-01 (original code)
# @since 2001-03-25
# @license http://www.gnu.org/copyleft/lesser.html LGPL
#
class I25Object extends BarcodeObject {
	
	#
	# Class Constructor.
	# @param int $Width Image width in pixels.
	# @param int $Height Image height in pixels. 
	# @param int $Style Barcode style.
	# @param int $Value value to print on barcode.
	#
	def __construct($Width, $Height, $Style, $Value)
		parent::__construct($Width, $Height, $Style);
		@mValue = $Value;
		@mCharSet = array (
		# 0# "00110",
		# 1# "10001",
		# 2# "01001",
		# 3# "11000",
		# 4# "00101",
		# 5# "10100",
		# 6# "01100",
		# 7# "00011",
		# 8# "10010",
		# 9# "01010"
		);
	end
	
	#
	# Returns barcode size.
	# @param int $xres Horizontal resolution.
	# @return barcode size.
	# @access private
	#
	def GetSize($xres)
		$len = @mValue.length;

		if ($len == 0)  {
			@mError = "Null value";
			return false;
		end

		for ($i=0;$i<$len;$i++)
			if ((@mValue[$i][0] < 48) || (@mValue[$i][0] > 57))
				@mError = "I25 is numeric only";
				return false;
			end
		end

		if (($len%2) != 0)
			@mError = "The length of barcode value must be even";
			return false;
		end
		$StartSize = BCD_I25_NARROW_BAR# 4 # $xres;
		$StopSize  = BCD_I25_WIDE_BAR# $xres + 2# BCD_I25_NARROW_BAR# $xres;
		$cPos = 0;
		$sPos = 0;
		do {
			$c1    = @mValue[$cPos];
			$c2    = @mValue[$cPos+1];
			$cset1 = @mCharSet[$c1];
			$cset2 = @mCharSet[$c2];

			for ($i=0;$i<5;$i++)
				$type1 = ($cset1[$i]==0) ? (BCD_I25_NARROW_BAR # $xres) : (BCD_I25_WIDE_BAR# $xres);
				$type2 = ($cset2[$i]==0) ? (BCD_I25_NARROW_BAR # $xres) : (BCD_I25_WIDE_BAR# $xres);
				$sPos += ($type1 + $type2);
			end
			$cPos+=2;
		end while ($cPos<$len);

		return $sPos + $StartSize + $StopSize;
	end

	#
	# Draws the start code.
	# @param int $DrawPos Drawing position.
	# @param int $yPos Vertical position.
	# @param int $ySize Vertical size.
	# @param int $xres Horizontal resolution.
	# @return int drawing position.
	# @access private
	#
	def DrawStart($DrawPos, $yPos, $ySize, $xres)
		# Start code is "0000"#
		@DrawSingleBar($DrawPos, $yPos, BCD_I25_NARROW_BAR # $xres , $ySize);
		$DrawPos += BCD_I25_NARROW_BAR # $xres;
		$DrawPos += BCD_I25_NARROW_BAR # $xres;
		@DrawSingleBar($DrawPos, $yPos, BCD_I25_NARROW_BAR # $xres , $ySize);
		$DrawPos += BCD_I25_NARROW_BAR # $xres;
		$DrawPos += BCD_I25_NARROW_BAR # $xres;
		return $DrawPos;
	end
	
	#
	# Draws the stop code.
	# @param int $DrawPos Drawing position.
	# @param int $yPos Vertical position.
	# @param int $ySize Vertical size.
	# @param int $xres Horizontal resolution.
	# @return int drawing position.
	# @access private
	#
	def DrawStop($DrawPos, $yPos, $ySize, $xres)
		# Stop code is "100"#
		@DrawSingleBar($DrawPos, $yPos, BCD_I25_WIDE_BAR# $xres , $ySize);
		$DrawPos += BCD_I25_WIDE_BAR # $xres;
		$DrawPos += BCD_I25_NARROW_BAR # $xres;
		@DrawSingleBar($DrawPos, $yPos, BCD_I25_NARROW_BAR # $xres , $ySize);
		$DrawPos += BCD_I25_NARROW_BAR # $xres;
		return $DrawPos;
	end

	#
	# Draws the barcode object.
	# @param int $xres Horizontal resolution.
	# @return bool true in case of success.
	#
	def DrawObject($xres)
		$len = @mValue.length;

		if (($size = GetSize($xres))==0)
			return false;
		end

		$cPos  = 0;

		if (@mStyle & BCS_DRAW_TEXT) $ysize = @mHeight - BCD_DEFAULT_MAR_Y1 - BCD_DEFAULT_MAR_Y2 - GetFontHeight(@mFont);
		else $ysize = @mHeight - BCD_DEFAULT_MAR_Y1 - BCD_DEFAULT_MAR_Y2;

		if (@mStyle & BCS_ALIGN_CENTER) $sPos = (integer)((@mWidth - $size ) / 2);
		elsif (@mStyle & BCS_ALIGN_RIGHT) $sPos = @mWidth - $size;
		else $sPos = 0;

		if (@mStyle & BCS_DRAW_TEXT)
			if (@mStyle & BCS_STRETCH_TEXT)
				# Stretch#
				for ($i=0;$i<$len;$i++)
					@DrawChar(@mFont, $sPos+BCD_I25_NARROW_BAR*4*$xres+($size/$len)*$i,
					$ysize + BCD_DEFAULT_MAR_Y1 + BCD_DEFAULT_TEXT_OFFSET , @mValue[$i]);
				end
			endelse# Center#
			$text_width = GetFontWidth(@mFont) * @mValue.length;
			@DrawText(@mFont, $sPos+(($size-$text_width)/2)+(BCD_I25_NARROW_BAR*4*$xres),
			$ysize + BCD_DEFAULT_MAR_Y1 + BCD_DEFAULT_TEXT_OFFSET, @mValue);
			end
		end

		$sPos = @DrawStart($sPos, BCD_DEFAULT_MAR_Y1, $ysize, $xres);
		do {
			$c1 = @mValue[$cPos];
			$c2 = @mValue[$cPos+1];
			$cset1 = @mCharSet[$c1];
			$cset2 = @mCharSet[$c2];

			for ($i=0;$i<5;$i++)
				$type1 = ($cset1[$i]==0) ? (BCD_I25_NARROW_BAR# $xres) : (BCD_I25_WIDE_BAR# $xres);
				$type2 = ($cset2[$i]==0) ? (BCD_I25_NARROW_BAR# $xres) : (BCD_I25_WIDE_BAR# $xres);
				@DrawSingleBar($sPos, BCD_DEFAULT_MAR_Y1, $type1 , $ysize);
				$sPos += ($type1 + $type2);
			end
			$cPos+=2;
		end while ($cPos<$len);
		$sPos =  @DrawStop($sPos, BCD_DEFAULT_MAR_Y1, $ysize, $xres);
		return true;
	end
}

#============================================================+
# END OF FILE
#============================================================+
