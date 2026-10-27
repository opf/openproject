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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Exports::PDF
  class DemoPDFStyles
    include MarkdownToPDF::Common
    include MarkdownToPDF::StyleHelper
    include Exports::PDF::Common::Styles
    include Exports::PDF::Components::PageStyles
    include Exports::PDF::Components::CoverStyles

    def initialize
      @styles = {
        cover: {
          hero: {
            padding_top: 120,
            title: {
              max_height: 30,
              spacing: 10,
              font: "SpaceMono"
            },
            heading: {
              spacing: 14,
              styles: ["bold"],
              size: 16
            }
          }
        }
      }
    end
  end

  class DemoGenerator < ::Exports::Exporter
    include Exports::PDF::Common::Common
    include Exports::PDF::Common::Logo
    include Exports::PDF::Components::Page
    include Exports::PDF::Components::Cover
    include Exports::PDF::Common::Attachments

    attr_reader :pdf

    def initialize
      super(nil)
      setup_page!
    end

    # This export is not tied to a particular AR model
    self.model = NilClass

    def self.key
      :demo_pdf
    end

    def styles
      @styles ||= DemoPDFStyles.new
    end

    def setup_page!
      @pdf = get_pdf
      configure_page_size!(:portrait)
      pdf.title = heading
      @page_count = 0
    end

    def export!
      render_demo
      success(pdf.render)
    rescue StandardError => e
      error(e)
    ensure
      delete_all_resized_images
    end

    def heading
      I18n.t("export.demo.heading")
    end

    def cover_page_heading
      heading
    end

    def cover_page_title
      Setting.app_title
    end

    def cover_page_dates
      nil
    end

    def cover_page_subheading
      nil
    end

    def footer_title
      I18n.t("export.demo.footer")
    end

    # Suggested filename
    def title
      "demo_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M')}.pdf"
    end

    def with_images?
      true
    end

    def header_footer_filter_pages
      [2]
    end

    def render_demo
      render_demo_page
      pdf.start_new_page
      render_demo_cover
      write_logo!
      write_footers!
    end

    def write_demo_text(text, size: 12, style: :normal)
      pdf.text(text, style:, size:)
      pdf.move_down 10
    end

    def render_demo_page
      write_demo_text heading.to_s, size: 22, style: :bold
      pdf.move_down 10

      write_demo_text "Regular"
      write_demo_text "Bold", style: :bold
      write_demo_text "Italic", style: :italic
      write_demo_text "Bold Italic", style: :bold_italic
      pdf.move_down 10

      write_demo_text(
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " \
        "Vivamus lacinia odio vitae vestibulum vestibulum. " \
        "Cras venenatis euismod malesuada.",
        size: 11
      )
    end

    def render_demo_cover
      write_cover_logo
      write_cover_hr
      write_cover_hero
      write_cover_footer
    end
  end
end
