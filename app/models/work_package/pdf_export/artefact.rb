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
  include Exports::PDF::Common::ProjectAttributes
  include Exports::PDF::Components::Page
  include Exports::PDF::Components::WpTable
  include Exports::PDF::Artefact::Cover
  include Exports::PDF::Artefact::Styles
  include Exports::PDF::Artefact::Toc
  include Exports::PDF::Artefact::Lifecycle
  include Exports::PDF::Artefact::Budgets
  include WorkPackage::PDFExport::Common::MarkdownField
  include WorkPackage::PDFExport::Wp::Attributes

  attr_accessor :pdf

  self.model = WorkPackage

  DEFAULT_TOC = true
  DEFAULT_INCLUDE_LIFECYCLE = true
  DEFAULT_INCLUDE_BUDGET = true

  alias :work_package :object

  delegate :project, to: :work_package

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
    write_toc! if with_toc?
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
    write_artefact_project_attributes
    write_artefact_lifecycle if with_lifecycle?
    write_artefact_budgets if with_budget?
    write_artefact_wp_attributes
  end

  def with_toc?
    boolean_option(:toc, DEFAULT_TOC)
  end

  def with_lifecycle?
    boolean_option(:include_lifecycle, DEFAULT_INCLUDE_LIFECYCLE)
  end

  def with_budget?
    boolean_option(:include_budget, DEFAULT_INCLUDE_BUDGET) && budget_enabled? && budget_allowed?
  end

  def boolean_option(key, default)
    return default if options[key].nil?

    ActiveModel::Type::Boolean.new.cast(options[key])
  end

  def toc_entries
    @toc_entries ||= build_toc_entries
  end

  def build_toc_entries
    build_project_attributes_toc_entries +
      build_lifecycle_toc_entries +
      build_budget_toc_entries +
      build_wp_attribute_group_toc_entries
  end

  def build_project_attributes_toc_entries
    collect_project_attributes_data.filter_map do |section|
      next if section[:fields].empty?

      toc_entry("project_section_#{section[:section_id]}", section[:caption])
    end
  end

  def build_lifecycle_toc_entries
    return [] unless with_lifecycle? && lifecycle_section?

    [toc_entry("lifecycle", I18n.t("pdf_generator.dialog.include_lifecycle.label"))]
  end

  def build_budget_toc_entries
    return [] unless with_budget? && budget_section?

    [toc_entry("budgets", I18n.t("pdf_generator.dialog.include_budget.label"))]
  end

  def build_wp_attribute_group_toc_entries
    work_package.type_variant.attribute_groups.map do |group|
      toc_entry("wp_group_#{group.key}", group.translated_key)
    end
  end

  def toc_entry(key, title)
    { id: "toc_#{key}", key:, title:, page_number: nil }
  end

  def record_toc_page!(key)
    return unless with_toc?

    entry = toc_entries.find { |e| e[:key] == key }
    return if entry.nil?

    entry[:page_number] = current_page_nr
    link_target_at_current_y(entry[:id])
  end

  # Renders all work package attribute sections with embedded work package
  # tables and custom fields (as shown in the work package form)
  def write_artefact_wp_attributes
    write_attributes!(work_package)
  end

  # Override WorkPackage::PDFExport::Wp::Attributes queries are
  # rendered as per work package attributes instead of one table
  def query_group_as_table?(_group)
    false
  end

  # Override WorkPackage::PDFExport::Wp::Attributes: render each related work
  # package with its description + long text custom fields (after the query
  # column fields written by super), taken from the work package itself
  # regardless of the query columns
  def write_related_work_package_attributes(work_package, column_entries)
    super
    write_related_work_package_long_texts(work_package)
  end

  def write_related_work_package_long_texts(work_package)
    write_related_work_package_long_text(work_package, work_package.description,
                                         WorkPackage.human_attribute_name(:description))
    work_package.custom_field_values
                .select { |custom_value| custom_value.custom_field.formattable? }
                .each do |custom_value|
      write_related_work_package_long_text(work_package, custom_value.value, custom_value.custom_field.name)
    end
  end

  # Renders the label in the work package attributes field label style,
  # followed by the markdown value
  def write_related_work_package_long_text(work_package, text, label)
    return if text.blank?

    write_long_text_custom_field!(work_package, text, label)
  end

  # Override the work package attribute group title in WorkPackage::PDFExport::Wp::Attributes
  def write_group_title(group, with_hr: true) # rubocop:disable Lint/UnusedMethodArgument
    write_optional_page_break
    record_toc_page!("wp_group_#{group.key}")
    write_section_title(group.translated_key)
  end

  def page_orientation_landscape?
    false
  end

  # Renders all project attribute sections (as shown in the work package project attributes tab)
  def write_artefact_project_attributes
    collect_project_attributes_data.each do |section|
      next if section[:fields].empty?

      write_optional_page_break
      record_toc_page!("project_section_#{section[:section_id]}")
      write_section(section)
    end
  end

  def collect_project_attributes_data # rubocop:disable Metrics/AbcSize
    ProjectCustomFieldSection
      .grouped_in_order(project.available_custom_fields_for_variant(work_package.type_variant&.id))
      .map do |section, custom_fields|
      {
        section_id: section.id,
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

  def write_section(section)
    with_margin(styles.section_margins) do
      write_section_title(section[:caption])
      write_project_detail_content(project, section[:fields])
    end
  end

  def write_section_title(text)
    with_margin(styles.section_title_margins) do
      style = styles.section_title
      pdf.formatted_text([style.merge({ text: })], style)
      write_section_title_hr
    end
  end

  def write_section_title_hr
    hr_style = styles.section_title_hr
    write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
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

  def heading
    @heading ||= "#{work_package.type} #{work_package.formatted_id}"
  end

  def footer_date
    heading
  end

  def footer_title
    work_package.subject
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
