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

module Exports::PDF::Artefact::Styles
  class PDFStyles
    include MarkdownToPDF::Common
    include MarkdownToPDF::StyleHelper
    include Exports::PDF::Common::Styles
    include Exports::PDF::Components::PageStyles
    include Exports::PDF::Components::WpTableStyles
    include Exports::PDF::Artefact::CoverStyles
    include Exports::PDF::Artefact::BudgetsStyles
    include Exports::PDF::Common::ProjectAttributesStyles
    include WorkPackage::PDFExport::Common::MarkdownFieldStyles
    include WorkPackage::PDFExport::Common::AttributesTableStyles

    # Styling for inline hint/error messages in reused work package components
    def inline_error
      resolve_font(@styles[:inline_error])
    end

    def inline_hint
      resolve_font(@styles[:inline_hint])
    end

    def page_subheading
      resolve_font(@styles[:page_subheading])
    end

    def page_subheading_margins
      resolve_margin(@styles[:page_subheading])
    end

    def page_head_margin
      resolve_margin(@styles[:page_head_margin])
    end

    def section_title
      resolve_font(@styles.dig(:section, :title))
    end

    def toc_margins
      resolve_margin(@styles.dig(:toc, :margins))
    end

    def toc_heading
      resolve_font(@styles.dig(:toc, :heading))
    end

    def toc_heading_margins
      resolve_margin(@styles.dig(:toc, :heading))
    end

    def toc_item
      resolve_font(@styles.dig(:toc, :item))
    end

    def toc_item_margins
      resolve_margin(@styles.dig(:toc, :item))
    end

    def section_title_hr
      {
        color: @styles.dig(:section, :title, :hr, :color),
        height: resolve_pt(@styles.dig(:section, :title, :hr, :height), 1)
      }
    end

    def cover_status_badge
      resolve_font(@styles.dig(:cover, :badge))
    end

    def cover_status_badge_offset
      resolve_pt(@styles.dig(:cover, :badge, :offset), 0)
    end

    def status_badge
      resolve_font(@styles.dig(:project, :badge))
    end

    def status_badge_offset
      resolve_pt(@styles.dig(:project, :badge, :offset), 0)
    end

    def section_title_margins
      resolve_margin(@styles.dig(:section, :title))
    end

    def section_margins
      resolve_margin(@styles[:section])
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
