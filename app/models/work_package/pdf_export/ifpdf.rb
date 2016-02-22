#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rfpdf/fpdf'

class WorkPackage::PdfExport::IFPDF < FPDF
  include Redmine::I18n
  attr_accessor :footer_date

  def initialize(lang)
    super()
    set_language_if_valid lang

    @font_for_content = 'Arial'
    @font_for_footer  = 'Helvetica'

    SetCreator(OpenProject::Info.app_name)
    SetFont(@font_for_content)
  end

  def SetFontStyle(style, size)
    SetFont(@font_for_content, style, size)
  end

  def SetTitle(txt)
    txt = begin
      utf16txt = txt.to_s.encode('UTF-16BE', 'UTF-8')
      hextxt = '<FEFF'  # FEFF is BOM
      hextxt << utf16txt.unpack('C*').map { |x| sprintf('%02X', x) }.join
      hextxt << '>'
    rescue
      txt
    end || ''
    super(txt)
  end

  def textstring(s)
    # Format a text string
    if s =~ /\A</  # This means the string is hex-dumped.
      return s
    else
      return '(' + escape(s) + ')'
    end
  end

  def fix_text_encoding(txt)
    # these quotation marks are not correctly rendered in the pdf
    txt = txt.gsub(/[â€œâ€�]/, '"') if txt
    txt = begin
      # 0x5c char handling
      txtar = txt.split('\\')
      txtar << '' if txt[-1] == ?\\
      txtar.map { |x| x.encode(l(:general_pdf_encoding), 'UTF-8') }.join('\\').gsub(/\\/, '\\\\\\\\')
    rescue
      txt
    end || ''
    txt
  end

  def RDMCell(w, h = 0, txt = '', border = 0, ln = 0, align = '', fill = 0, link = '')
    Cell(w, h, fix_text_encoding(txt), border, ln, align, fill, link)
  end

  def RDMMultiCell(w, h = 0, txt = '', border = 0, align = '', fill = 0)
    MultiCell(w, h, fix_text_encoding(txt), border, align, fill)
  end

  def Footer
    SetFont(@font_for_footer, 'I', 8)
    SetY(-15)
    SetX(15)
    RDMCell(0, 5, @footer_date, 0, 0, 'L')
    SetY(-15)
    SetX(-30)
    RDMCell(0, 5, PageNo().to_s + '/{nb}', 0, 0, 'C')
  end
  alias alias_nb_pages AliasNbPages
end
