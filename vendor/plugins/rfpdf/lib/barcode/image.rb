
#============================================================+
# File name   : image.rb
# Begin       : 2002-07-31
# Last Update : 2005-01-08
# Author      : Karim Mribti [barcode@mribti.com]
#             : Nicola Asuni [info@tecnick.com]
# Version     : 0.0.8a  2001-04-01 (original code)
# License     : GNU LGPL (Lesser General Public License) 2.1
#               http://www.gnu.org/copyleft/lesser.txt
# Source Code : http://www.mribti.com/barcode/
#
# Description : Barcode Image Rendering.
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
# Barcode Image Rendering.
# @author Karim Mribti, Nicola Asuni
# @name BarcodeObject
# @package com.tecnick.tcpdf
# @@version 0.0.8a  2001-04-01 (original code)
# @since 2001-03-25
# @license http://www.gnu.org/copyleft/lesser.html LGPL
#

#
# 
#

require("../../shared/barcode/barcode.rb");
require("../../shared/barcode/i25object.rb");
require("../../shared/barcode/c39object.rb");
require("../../shared/barcode/c128aobject.rb");
require("../../shared/barcode/c128bobject.rb");
require("../../shared/barcode/c128cobject.rb");

if (!$_REQUEST['style'].nil?) $_REQUEST['style'] = BCD_DEFAULT_STYLE;
if (!$_REQUEST['width'].nil?) $_REQUEST['width'] = BCD_DEFAULT_WIDTH;
if (!$_REQUEST['height'].nil?) $_REQUEST['height'] = BCD_DEFAULT_HEIGHT;
if (!$_REQUEST['xres'].nil?) $_REQUEST['xres'] = BCD_DEFAULT_XRES;
if (!$_REQUEST['font'].nil?) $_REQUEST['font'] = BCD_DEFAULT_FONT;
if (!$_REQUEST['type'].nil?) $_REQUEST['type'] = "C39";
if (!$_REQUEST['code'].nil?) $_REQUEST['code'] = "";

switch ($_REQUEST['type'].upcase)
	case "I25"
		$obj = new I25Object($_REQUEST['width'], $_REQUEST['height'], $_REQUEST['style'], $_REQUEST['code']);
		break;
	end
	case "C128A"
		$obj = new C128AObject($_REQUEST['width'], $_REQUEST['height'], $_REQUEST['style'], $_REQUEST['code']);
		break;
	end
	case "C128B"
		$obj = new C128BObject($_REQUEST['width'], $_REQUEST['height'], $_REQUEST['style'], $_REQUEST['code']);
		break;
	end
	case "C128C"
		$obj = new C128CObject($_REQUEST['width'], $_REQUEST['height'], $_REQUEST['style'], $_REQUEST['code']);
		break;
	end
	case "C39":
	default
		$obj = new C39Object($_REQUEST['width'], $_REQUEST['height'], $_REQUEST['style'], $_REQUEST['code']);
		break;
	end
}

if ($obj)
	$obj->SetFont($_REQUEST['font']);   
	$obj->DrawObject($_REQUEST['xres']);
	$obj->FlushObject();
	$obj->DestroyObject();
	unset($obj);  # clean#
}

#============================================================+
# END OF FILE                                                 
#============================================================+
