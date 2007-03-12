# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'iconv'
require 'rfpdf/chinese'

module IfpdfHelper  
  
  class IFPDF < FPDF
    include GLoc
    attr_accessor :footer_date
    
    def initialize(lang)
      super()
      set_language_if_valid lang
      case current_language
      when :ja
        extend(PDF_Japanese)
        AddSJISFont()
        @font_for_content = 'SJIS'
        @font_for_footer = 'SJIS'
      else
        @font_for_content = 'Arial'
        @font_for_footer = 'Helvetica'              
      end
      SetCreator("redMine #{Redmine::VERSION}")
      SetFont(@font_for_content)
    end
    
    def SetFontStyle(style, size)
      SetFont(@font_for_content, style, size)
    end
      
    def Cell(w,h=0,txt='',border=0,ln=0,align='',fill=0,link='')
      @ic ||= Iconv.new(l(:general_pdf_encoding), 'UTF-8')
      txt = begin
        @ic.iconv(txt)
      rescue
        txt
      end
      super w,h,txt,border,ln,align,fill,link
    end
    
    def Footer
      SetFont(@font_for_footer, 'I', 8)
      SetY(-15)
      SetX(15)
      Cell(0, 5, @footer_date, 0, 0, 'L')
      SetY(-15)
      SetX(-30)
      Cell(0, 5, PageNo().to_s + '/{nb}', 0, 0, 'C')
    end
    
  end

end
