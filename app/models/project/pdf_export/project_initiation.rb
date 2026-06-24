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

class Project::PDFExport::ProjectInitiation < Exports::Exporter
  include Exports::PDF::Common::Common
  include Exports::PDF::Common::Attachments
  include Exports::PDF::Common::Logo
  include Exports::PDF::Common::Macro
  include Exports::PDF::Common::Markdown
  include Exports::PDF::Common::Badge
  include Exports::PDF::Components::Page
  include Project::PDFExport::Common::ProjectAttributes
  include Project::PDFExport::ProjectInitiation::Cover
  include Project::PDFExport::ProjectInitiation::Styles
  include ProjectsHelper

  attr_accessor :pdf

  self.model = Project

  alias :project :object

  def self.key
    :project_initiation_export_pdf
  end

  def initialize(project, _options = {})
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
    render_project_initiation
    render_again_with_total_page_nrs
  end

  def render_again_with_total_page_nrs
    @total_page_nr = pdf.page_count + @page_count
    @page_count = 0
    setup_page! # clear current pdf
    render_project_initiation
  end

  def render_project_initiation
    pdf.title = heading
    write_cover_page! if with_cover?
    with_margin(styles.page_head_margin) do
      write_project_initiation_title
      write_project_initiation_heading
      write_project_initiation_description
    end
    write_project_initiation
    write_headers_footers
  end

  def write_headers_footers
    write_logo!
    write_footers!
  end

  def export_datetime
    @export_datetime = Time.zone.now
  end

  def cover_page_heading
    heading
  end

  def cover_page_title
    project.name
  end

  def cover_page_footers
    [
      Setting.app_title,
      format_time(export_datetime)
    ].compact
  end

  def write_cover_heading
    status = project_initiation_status
    return super if status.nil?

    write_cover_heading_with_badge(status.name, status_prawn_color(status), styles.cover_status_badge_offset)
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

  def footer_date
    heading
  end

  def heading
    @heading ||= project_creation_wizard_name(project)
  end

  def footer_title
    project.name
  end

  def title
    # <project.identifier>_<wizard type name>_<WP status>_<yyyy-mm-dd_hh:mm>.pdf
    build_pdf_filename([project.identifier, heading, project_initiation_status_name].compact.join("_"))
  end

  def with_images?
    true
  end

  def with_cover?
    true
  end

  def can_view_attribute?(_project, _attribute)
    true
  end

  def hide_empty_attributes?
    false
  end

  def attributes_in_table?
    false
  end

  def enabled_in_wizard_ids
    project
      .project_custom_field_project_mappings
      .where(creation_wizard: true)
      .select(:custom_field_id)
  end

  def collect_custom_fields_data # rubocop:disable Metrics/AbcSize
    project.available_custom_fields
           .where(id: enabled_in_wizard_ids)
           .order("custom_fields.id")
           .group_by(&:project_custom_field_section)
           .map do |section, custom_fields|
             {
               caption: section.name,
               fields: custom_fields.each_with_object([]) do |custom_field, fields|
                 fields << {
                   key: "cf_#{custom_field.id}",
                   caption: custom_field.name,
                   custom_field:
                 }
                 if custom_field.has_comment?
                   fields << {
                     key: "cfc_#{custom_field.id}",
                     caption: I18n.t(:label_custom_comment, name: custom_field.name),
                     custom_field:
                   }
                 end
               end
             }
    end
  end

  def write_section_title_hr
    hr_style = styles.section_title_hr
    write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
  end

  def write_section_title(text)
    with_margin(styles.section_title_margins) do
      style = styles.section_title
      pdf.formatted_text([style.merge({ text: })], style)
      write_section_title_hr
    end
  end

  def write_section(section)
    with_margin(styles.section_margins) do
      write_section_title(section[:caption])
      write_project_detail_content(project, section[:fields])
    end
  end

  def write_project_initiation_title
    status = project_initiation_status
    return write_subheading if status.nil?

    write_subheading_with_badge(status.name, status_prawn_color(status))
  end

  def write_project_initiation_heading
    with_margin(styles.page_heading_margins) do
      style = styles.page_heading
      pdf.formatted_text([style.merge({ text: project.name })], style)
    end
  end

  def write_subheading
    with_margin(styles.page_subheading_margins) do
      style = styles.page_subheading
      pdf.formatted_text([style.merge({ text: heading })], style)
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

  def write_project_initiation_description
    description = project.description
    return if description.blank?

    write_project_markdown(project, description, nil)
  end

  def project_initiation_status_name
    project_initiation_status&.name
  end

  def project_initiation_status
    status = project_initiation_work_package_status
    return status unless status.nil?

    return nil if project.project_creation_wizard_status_when_submitted_id.blank?

    Status.find_by(id: project.project_creation_wizard_status_when_submitted_id)
  end

  def project_initiation_work_package_status
    return nil if project.project_creation_wizard_artifact_work_package_id.blank?

    work_package = WorkPackage.visible.find_by(id: project.project_creation_wizard_artifact_work_package_id)
    work_package&.status
  end

  def write_project_initiation
    collect_custom_fields_data.each do |section|
      next if section[:fields].empty?

      write_optional_page_break
      write_section(section)
    end
  end
end
