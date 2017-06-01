#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class WorkPackage::PdfExport::View

  include Prawn::View
  include Redmine::I18n

  def initialize(lang)
    set_language_if_valid lang
  end

  def options
    @options ||= {}
  end

  def info
    @info ||= {
      Creator: OpenProject::Info.app_name,
      CreationDate: Time.now
    }
  end

  def document
    @document ||= Prawn::Document.new(options.merge(info: info)).tap do |document|
      register_fonts! document

      document.set_font document.font('NotoSans')
      document.fallback_fonts = fallback_fonts
    end
  end

  def fallback_fonts
    []
  end

  def register_fonts!(document)
    font_path = Rails.root.join('public/fonts')

    document.font_families['NotoSans'] = {
      normal: {
        file: font_path.join('noto/NotoSans-Regular.ttf'),
        font: 'NotoSans-Regular'
      },
      italic: {
        file: font_path.join('noto/NotoSans-Italic.ttf'),
        font: 'NotoSans-Italic'
      },
      bold: {
        file: font_path.join('noto/NotoSans-Bold.ttf'),
        font: 'NotoSans-Bold'
      },
      bold_italic: {
        file: font_path.join('noto/NotoSans-BoldItalic.ttf'),
        font: 'NotoSans-BoldItalic'
      }
    }
  end

  def title=(title)
    info[:Title] = title
  end

  def title
    info[:Title]
  end

  def font(name: nil, style: nil, size: nil)
    name ||= document.font.basename.split('-').first # e.g. NotoSans-Bold => NotoSans
    font_opts = {}
    font_opts[:style] = style if style

    document.font name, font_opts
    document.font_size size if size

    document.font
  end
end
