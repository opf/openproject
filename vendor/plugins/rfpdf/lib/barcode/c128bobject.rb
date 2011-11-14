#-- encoding: UTF-8

#============================================================+
# File name   : c128bobject.rb
# Begin       : 2002-07-31
# Last Update : 2004-12-29
# Author      : Karim Mribti [barcode@mribti.com]
# Version     : 0.0.8a  2001-04-01 (original code)
# License     : GNU LGPL (Lesser General Public License) 2.1
#               http://www.gnu.org/copyleft/lesser.txt
# Source Code : http://www.mribti.com/barcode/
#
# Description : Code 128-B Barcode Render Class for PHP using
#               the GD graphics library.
#               Code 128-B is a continuous, multilevel and full
#               ASCII code.
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
# Code 128-B Barcode Render Class for PHP using the GD graphics library.<br>
# Code 128-B is a continuous, multilevel and full ASCII code.
# @author Karim Mribti, Nicola Asuni
# @name BarcodeObject
# @package com.tecnick.tcpdf
# @@version 0.0.8a  2001-04-01 (original code)
# @since 2001-03-25
# @license http://www.gnu.org/copyleft/lesser.html LGPL
#

#
# Code 128-B Barcode Render Class for PHP using the GD graphics library.<br>
# Code 128-B is a continuous, multilevel and full ASCII code.
# @author Karim Mribti, Nicola Asuni
# @name BarcodeObject
# @package com.tecnick.tcpdf
# @@version 0.0.8a  2001-04-01 (original code)
# @since 2001-03-25
# @license http://www.gnu.org/copyleft/lesser.html LGPL
#
class C128BObject extends BarcodeObject {
	
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
		@mChars = " !\"#$%&'()*+�-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{ }~";
		@mCharSet = array (
		"212222",   #   00#
		"222122",   #   01#
		"222221",   #   02#
		"121223",   #   03#
		"121322",   #   04#
		"131222",   #   05#
		"122213",   #   06#
		"122312",   #   07#
		"132212",   #   08#
		"221213",   #   09#
		"221312",   #   10#
		"231212",   #   11#
		"112232",   #   12#
		"122132",   #   13#
		"122231",   #   14#
		"113222",   #   15#
		"123122",   #   16#
		"123221",   #   17#
		"223211",   #   18#
		"221132",   #   19#
		"221231",   #   20#
		"213212",   #   21#
		"223112",   #   22#
		"312131",   #   23#
		"311222",   #   24#
		"321122",   #   25#
		"321221",   #   26#
		"312212",   #   27#
		"322112",   #   28#
		"322211",   #   29#
		"212123",   #   30#
		"212321",   #   31#
		"232121",   #   32#
		"111323",   #   33#
		"131123",   #   34#
		"131321",   #   35#
		"112313",   #   36#
		"132113",   #   37#
		"132311",   #   38#
		"211313",   #   39#
		"231113",   #   40#
		"231311",   #   41#
		"112133",   #   42#
		"112331",   #   43#
		"132131",   #   44#
		"113123",   #   45#
		"113321",   #   46#
		"133121",   #   47#
		"313121",   #   48#
		"211331",   #   49#
		"231131",   #   50#
		"213113",   #   51#
		"213311",   #   52#
		"213131",   #   53#
		"311123",   #   54#
		"311321",   #   55#
		"331121",   #   56#
		"312113",   #   57#
		"312311",   #   58#
		"332111",   #   59#
		"314111",   #   60#
		"221411",   #   61#
		"431111",   #   62#
		"111224",   #   63#
		"111422",   #   64#
		"121124",   #   65#
		"121421",   #   66#
		"141122",   #   67#
		"141221",   #   68#
		"112214",   #   69#
		"112412",   #   70#
		"122114",   #   71#
		"122411",   #   72#
		"142112",   #   73#
		"142211",   #   74#
		"241211",   #   75#
		"221114",   #   76#
		"413111",   #   77#
		"241112",   #   78#
		"134111",   #   79#
		"111242",   #   80#
		"121142",   #   81#
		"121241",   #   82#
		"114212",   #   83#
		"124112",   #   84#
		"124211",   #   85#
		"411212",   #   86#
		"421112",   #   87#
		"421211",   #   88#
		"212141",   #   89#
		"214121",   #   90#
		"412121",   #   91#
		"111143",   #   92#
		"111341",   #   93#
		"131141",   #   94#
		"114113",   #   95#
		"114311",   #   96#
		"411113",   #   97#
		"411311",   #   98#
		"113141",   #   99#
		"114131",   #  100#
		"311141",   #  101#
		"411131"    #  102#
		);
	end

	#
	# Returns the character index.
	# @param char $char character.
	# @return int character index or -1 in case of error.
	# @access private
	#
	def GetCharIndex($char)
		for ($i=0;$i<95;$i++)
			if (@mChars[$i] == $char)
				return $i;
			end
		end
		return -1;
	end
	
	#
	# Returns the bar size.
	# @param int $xres Horizontal resolution.
	# @param char $char Character.
	# @return int barcode size.
	# @access private
	#
	def GetBarSize($xres, $char)
		switch ($char)
			case '1'
				$cVal = BCD_C128_BAR_1;
				
			case '2'
				$cVal = BCD_C128_BAR_2;
				
			case '3'
				$cVal = BCD_C128_BAR_3;
				
			case '4'
				$cVal = BCD_C128_BAR_4;
				
			default
				$cVal = 0;
			end
		end
		return  $cVal# $xres;
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
		$ret = 0;
		for ($i=0;$i<$len;$i++)
			if (($id = GetCharIndex(@mValue[$i])) == -1)
				@mError = "C128B not include the char '".@mValue[$i]."'";
				return false;
			else
				$cset = @mCharSet[$id];
				$ret += GetBarSize($xres, $cset[0]);
				$ret += GetBarSize($xres, $cset[1]);
				$ret += GetBarSize($xres, $cset[2]);
				$ret += GetBarSize($xres, $cset[3]);
				$ret += GetBarSize($xres, $cset[4]);
				$ret += GetBarSize($xres, $cset[5]);
			end
		end
		# length of Check character#
		$cset = GetCheckCharValue();
		$CheckSize = 0;
		for ($i=0;$i<6;$i++)
			$CheckSize += GetBarSize($cset[$i], $xres);
		end

		$StartSize = 2*BCD_C128_BAR_2*$xres + 3*BCD_C128_BAR_1*$xres + BCD_C128_BAR_4*$xres;
		$StopSize  = 2*BCD_C128_BAR_2*$xres + 3*BCD_C128_BAR_1*$xres + 2*BCD_C128_BAR_3*$xres;

		return $StartSize + $ret + $CheckSize + $StopSize;
	end
	
	#
	# Returns the check-char value.
	# @return string.
	# @access private
	#
	def GetCheckCharValue()
		$len = @mValue.length;
		$sum = 104; # 'B' type;
		for ($i=0;$i<$len;$i++)
			$sum += GetCharIndex(@mValue[$i])# ($i+1);
		end
		$check  = $sum % 103;
		return @mCharSet[$check];
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
		# Start code is '211214'#
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize('2', $xres), $ySize);
		$DrawPos += GetBarSize('2', $xres);
		$DrawPos += GetBarSize('1', $xres);
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize('1', $xres), $ySize);
		$DrawPos += GetBarSize('1', $xres);
		$DrawPos += GetBarSize('2', $xres);
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize('1', $xres), $ySize);
		$DrawPos += GetBarSize('1', $xres);
		$DrawPos += GetBarSize('4', $xres);
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
		# Stop code is '2331112'#
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize('2', $xres) , $ySize);
		$DrawPos += GetBarSize('2', $xres);
		$DrawPos += GetBarSize('3', $xres);
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize('3', $xres) , $ySize);
		$DrawPos += GetBarSize('3', $xres);
		$DrawPos += GetBarSize('1', $xres);
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize('1', $xres) , $ySize);
		$DrawPos += GetBarSize('1', $xres);
		$DrawPos += GetBarSize('1', $xres);
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize('2', $xres) , $ySize);
		$DrawPos += GetBarSize('2', $xres);
		return $DrawPos;
	end
	
	#
	# Draws the check-char code.
	# @param int $DrawPos Drawing position.
	# @param int $yPos Vertical position.
	# @param int $ySize Vertical size.
	# @param int $xres Horizontal resolution.
	# @return int drawing position.
	# @access private
	#
	def DrawCheckChar($DrawPos, $yPos, $ySize, $xres)
		$cset = GetCheckCharValue();
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize($cset[0], $xres) , $ySize);
		$DrawPos += GetBarSize($cset[0], $xres);
		$DrawPos += GetBarSize($cset[1], $xres);
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize($cset[2], $xres) , $ySize);
		$DrawPos += GetBarSize($cset[2], $xres);
		$DrawPos += GetBarSize($cset[3], $xres);
		@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize($cset[4], $xres) , $ySize);
		$DrawPos += GetBarSize($cset[4], $xres);
		$DrawPos += GetBarSize($cset[5], $xres);
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

		if (@mStyle & BCS_ALIGN_CENTER) $sPos = (integer)((@mWidth - $size ) / 2);
		elsif (@mStyle & BCS_ALIGN_RIGHT) $sPos = @mWidth - $size;
		else $sPos = 0;

		# Total height of bar code -Bars only-#
		if (@mStyle & BCS_DRAW_TEXT) $ysize = @mHeight - BCD_DEFAULT_MAR_Y1 - BCD_DEFAULT_MAR_Y2 - GetFontHeight(@mFont);
		else $ysize = @mHeight - BCD_DEFAULT_MAR_Y1 - BCD_DEFAULT_MAR_Y2;

		# Draw text#
		if (@mStyle & BCS_DRAW_TEXT)
			if (@mStyle & BCS_STRETCH_TEXT)
				for ($i=0;$i<$len;$i++)
					@DrawChar(@mFont, $sPos+(2*BCD_C128_BAR_2*$xres + 3*BCD_C128_BAR_1*$xres + BCD_C128_BAR_4*$xres)+($size/$len)*$i,
					$ysize + BCD_DEFAULT_MAR_Y1 + BCD_DEFAULT_TEXT_OFFSET, @mValue[$i]);
				else# Center#
			$text_width = GetFontWidth(@mFont)# @mValue.length;
			@DrawText(@mFont, $sPos+(($size-$text_width)/2)+(2*BCD_C128_BAR_2*$xres + 3*BCD_C128_BAR_1*$xres + BCD_C128_BAR_4*$xres),
			$ysize + BCD_DEFAULT_MAR_Y1 + BCD_DEFAULT_TEXT_OFFSET, @mValue);
			end
		end

		$cPos = 0;
		$DrawPos = @DrawStart($sPos, BCD_DEFAULT_MAR_Y1 , $ysize, $xres);
		do {
			$c     = GetCharIndex(@mValue[$cPos]);
			$cset  = @mCharSet[$c];
			@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize($cset[0], $xres) , $ysize);
			$DrawPos += GetBarSize($cset[0], $xres);
			$DrawPos += GetBarSize($cset[1], $xres);
			@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize($cset[2], $xres) , $ysize);
			$DrawPos += GetBarSize($cset[2], $xres);
			$DrawPos += GetBarSize($cset[3], $xres);
			@DrawSingleBar($DrawPos, BCD_DEFAULT_MAR_Y1, GetBarSize($cset[4], $xres) , $ysize);
			$DrawPos += GetBarSize($cset[4], $xres);
			$DrawPos += GetBarSize($cset[5], $xres);
			$cPos += 1;
		end while ($cPos<$len);
		$DrawPos = @DrawCheckChar($DrawPos, BCD_DEFAULT_MAR_Y1 , $ysize, $xres);
		$DrawPos =  @DrawStop($DrawPos, BCD_DEFAULT_MAR_Y1 , $ysize, $xres);
		return true;
	end
}

#============================================================+
# END OF FILE
#============================================================+
