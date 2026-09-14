# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::Exports::PDFExport::Styles
  class PDFStyles
    include MarkdownToPDF::Common
    include MarkdownToPDF::StyleHelper
    include Exports::PDF::Common::Styles
    include Exports::PDF::Components::PageStyles
    include Exports::PDF::Components::CoverStyles
    include Exports::PDF::Components::WpTableStyles
    include WorkPackage::PDFExport::Common::AttributesTableStyles
    include Exports::PDF::Common::ProjectAttributesStyles

    def project_title
      resolve_font(@styles.dig(:project, :title))
    end

    def project_title_margins
      resolve_margin(@styles.dig(:project, :title))
    end

    def project_margins
      resolve_margin(@styles[:project])
    end

    def toc_title
      resolve_font(@styles.dig(:toc, :title))
    end

    def toc_title_margins
      resolve_margin(@styles.dig(:toc, :title))
    end

    def toc_max_depth
      @styles.dig(:toc, :max_depth) || 4
    end

    def toc_margins
      resolve_margin(@styles[:toc])
    end

    def toc_indent_mode
      @styles.dig(:toc, :indent_mode)
    end

    def toc_item(level)
      resolve_font(@styles.dig(:toc, :item)).merge(
        resolve_font(@styles.dig(:toc, :"item_level_#{level}"))
      )
    end

    def toc_item_subject_indent
      resolve_pt(@styles.dig(:toc, :subject_indent), 4)
    end

    def toc_item_margins(level)
      resolve_margin(@styles.dig(:toc, :item)).merge(
        resolve_margin(@styles.dig(:toc, :"item_level_#{level}"))
      )
    end
  end

  def styles
    @styles ||= PDFStyles.new(styles_asset_path)
  end

  private

  def styles_asset_path
    File.dirname(File.expand_path(__FILE__))
  end
end
