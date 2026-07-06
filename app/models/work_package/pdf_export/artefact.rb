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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackage::PDFExport::Artefact < Exports::Exporter
  include Exports::PDF::Common::Common
  include Exports::PDF::Common::Attachments
  include Exports::PDF::Common::Logo
  include Exports::PDF::Common::Macro
  include Exports::PDF::Common::Markdown
  include Exports::PDF::Common::Badge
  include Exports::PDF::Components::Page
  include Exports::PDF::Artefact::Cover
  include Exports::PDF::Artefact::Styles

  attr_accessor :pdf

  self.model = WorkPackage

  alias :work_package :object

  def self.key
    :artefact_export_pdf
  end

  def initialize(work_package, _options = {})
    super

    @page_count = 0
    setup_page!
  end

  def setup_page!
    self.pdf = get_pdf
    configure_page_size!(:portrait)
    pdf.title = heading
  end

  def export!
    render_doc
    success(pdf.render)
  rescue StandardError => e
    error(e)
  ensure
    delete_all_resized_images
  end

  def render_doc
    render_artefact
    render_again_with_total_page_nrs
  end

  def render_again_with_total_page_nrs
    @total_page_nr = pdf.page_count + @page_count
    @page_count = 0
    setup_page! # clear current pdf
    render_artefact
  end

  def render_artefact
    pdf.title = heading
    write_cover_page! if with_cover?
    with_margin(styles.page_head_margin) do
      write_artefact_title
      write_artefact_heading
      write_artefact_description
    end
    write_artefact
    write_headers_footers
  end

  def write_headers_footers
    write_logo!
    write_footers!
  end

  def export_datetime
    @export_datetime = Time.zone.now
  end

  # Cover page (Exports::PDF::Artefact::Cover)

  def cover_page_heading
    "#{work_package.type} #{work_package.formatted_id}"
  end

  def cover_page_title
    work_package.subject
  end

  def cover_page_footers
    [
      Setting.app_title,
      format_time(export_datetime)
    ].compact
  end

  def write_cover_heading
    write_cover_heading_with_badge(
      work_package.status.name,
      wp_status_prawn_color(work_package),
      styles.cover_status_badge_offset
    )
  end

  def write_cover_heading_with_badge(badge_text, color, offset)
    text_style = styles.cover_heading
    prawn_draw_text_box(
      badge_fragments(cover_page_heading, text_style, badge_text, color, offset, styles.cover_status_badge),
      badge_options(text_style, badge_text, offset),
      styles.cover_heading_margin,
      styles.cover_heading_padding,
      styles.cover_heading_border
    )
  end

  # Content page

  def write_artefact_title
    write_subheading_with_badge(work_package.status.name, wp_status_prawn_color(work_package))
  end

  def write_artefact_heading
    with_margin(styles.page_heading_margins) do
      style = styles.page_heading
      pdf.formatted_text([style.merge({ text: work_package.subject })], style)
    end
  end

  def write_subheading_with_badge(badge_text, color)
    offset = styles.status_badge_offset
    text_style = styles.page_subheading
    with_margin(styles.page_subheading_margins) do
      pdf.formatted_text(
        badge_fragments(heading, text_style, badge_text, color, offset, styles.status_badge),
        badge_options(text_style, badge_text, offset)
      )
    end
  end

  def badge_fragments(text, text_style, badge_text, color, offset, badge_style)
    [
      text_style.merge({ text: }),
      { text: " " },
      prawn_badge(badge_text, color, offset: offset, font_size: badge_style[:size], line_height: badge_style[:size])
    ]
  end

  def badge_options(text_style, badge_text, offset)
    text_style.merge(draw_text_callback: prawn_badge_draw_text_callback(badge_text, offset))
  end

  def write_artefact_description
    description = work_package.description
    return if description.blank?

    with_margin(styles.project_markdown_margins) do
      write_markdown!(
        apply_markdown_field_macros(description, { work_package:, project: work_package.project, user: User.current }),
        styles.project_markdown_styling_yml
      )
    end
  end

  def write_artefact
    # TODO: render the pmflex artefact content (to be implemented)
  end

  def heading
    @heading ||= "#{work_package.type} #{work_package.formatted_id}"
  end

  def footer_date
    heading
  end

  def footer_title
    options[:footer_text] || work_package.subject
  end

  def title
    # <project.identifier>_<type>_<ID>_<subject>_<yyyy-mm-dd_hh:mm>.pdf
    build_pdf_filename([work_package.project.identifier, work_package.type,
                        work_package.display_id, work_package.subject].join("_"))
  end

  def with_images?
    true
  end

  def with_cover?
    true
  end
end
