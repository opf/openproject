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

class WorkPackage::PDFExport::WorkPackageToPdf < Exports::Exporter
  include Exports::PDF::Common::Common
  include Exports::PDF::Common::Logo
  include Exports::PDF::Common::Attachments
  include Exports::PDF::Common::Badge
  include Exports::PDF::Components::Page
  include Exports::PDF::Components::WpTable
  include WorkPackage::PDFExport::Wp::Styles
  include WorkPackage::PDFExport::Wp::Attributes
  include WorkPackage::PDFExport::Common::MarkdownField

  attr_accessor :pdf

  self.model = WorkPackage

  alias :work_package :object

  def self.key
    :pdf
  end

  def initialize(work_package, _options = {})
    super

    setup_page!
  end

  def export!
    render_work_package
    success(pdf.render)
  rescue StandardError => e
    error(e)
  ensure
    delete_all_resized_images
  end

  def setup_page!
    self.pdf = get_pdf
    @page_count = 0
    configure_page_size!(page_orientation_layout)
  end

  def page_orientation_layout
    options[:page_orientation] == "landscape" ? :landscape : :portrait
  end

  def page_orientation_landscape?
    @page_orientation_landscape ||= page_orientation_layout == :landscape
  end

  def render_work_package
    pdf.title = heading
    write_wp_title! work_package
    write_attributes! work_package
    write_description! work_package
    write_headers!
    write_footers!
  end

  def write_wp_title!(work_package)
    badge_text = work_package.status.name.downcase
    offset = 2
    style = styles.page_heading
    with_margin(styles.page_heading_margins) do
      pdf.formatted_text(
        [
          wp_title_formatted_text(work_package, style),
          { text: " " },
          prawn_badge(badge_text, wp_status_prawn_color(work_package), offset:, line_height: style[:size])
        ],
        style.merge({ draw_text_callback: prawn_badge_draw_text_callback(badge_text, offset) })
      )
    end
  end

  def wp_title_formatted_text(work_package, style)
    style.merge({ text: heading, link: url_helpers.work_package_url(work_package) })
  end

  def heading
    "#{work_package.type} #{work_package.formatted_id} - #{work_package.subject}"
  end

  def footer_title
    options[:footer_text]
  end

  def title
    # <project>_<type>_<ID>_<subject><YYYY-MM-DD>_<HH-MM>.pdf
    build_pdf_filename([work_package.project, work_package.type,
                        work_package.display_id, work_package.subject].join("_"))
  end

  def write_description!(work_package)
    write_markdown_field!(work_package, work_package.description, WorkPackage.human_attribute_name(:description))
  end

  def with_images?
    true
  end
end
