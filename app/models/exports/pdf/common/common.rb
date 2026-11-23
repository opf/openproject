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

module Exports::PDF::Common::Common
  include WorkPackage::Exports::Attributes
  include Redmine::I18n
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper
  include CustomFieldsHelper
  include OpenProject::TextFormatting
  include Exports::PDF::Common::Text

  # Languages supported by the hyphenation library https://rubygems.org/gems/text-hyphen
  # The labels are the language names in the language itself (NOT to be put I18n)
  HYPHENATION_LANGUAGES = {
    "ca" => "Català",
    "da" => "Dansk",
    "de" => "Deutsch",
    "et" => "Eesti",
    "en" => "English",
    "es" => "Español",
    "eu" => "Euskara",
    "fr" => "Français",
    "ga" => "Gaeilge",
    "hr" => "Hrvatski",
    "id" => "Indonesia",
    "ia" => "Interlingua",
    "it" => "Italiano",
    "hu" => "Magyar",
    "ms" => "Melayu",
    "nl" => "Nederlands",
    "no" => "Norsk",
    "pl" => "Polski",
    "pt" => "Português",
    "sk" => "Slovenčina",
    "fi" => "Suomi",
    "sv" => "Svenska",
    "is" => "Ísland",
    "cs" => "Čeština",
    "mn" => "Монгол",
    "ru" => "Русский"
  }.freeze

  private

  def get_pdf
    ::Exports::PDF::Common::View.new(current_language)
  end

  def field_value(work_package, attribute)
    value = work_package.send(attribute)

    case value
    when Date
      format_date value
    when Time
      format_time value
    else
      value.to_s
    end
  end

  def success(content)
    ::Exports::Result
      .new format: :pdf,
           title:,
           content:,
           mime_type: "application/pdf"
  end

  def error(pdf_error, custom_message = nil)
    message = custom_message || I18n.t(:error_pdf_failed_to_export, error: pdf_error.message)
    result = ::Exports::ExportError.new message
    result.set_backtrace pdf_error.backtrace
    raise result
  end

  def with_padding(opts, &)
    with_vertical_padding(opts) do
      pdf.indent(opts[:left_padding] || 0, opts[:right_padding] || 0, &)
    end
  end

  def with_vertical_padding(opts)
    pdf.move_down(opts[:top_padding]) if opts.key?(:top_padding)
    yield
    pdf.move_down(opts[:bottom_padding]) if opts.key?(:bottom_padding)
  end

  def with_margin(opts, &)
    with_vertical_margin(opts) do
      pdf.indent(opts[:left_margin] || 0, opts[:right_margin] || 0, &)
    end
  end

  def with_vertical_margin(opts)
    pdf.move_down(opts[:top_margin]) if opts.key?(:top_margin)
    yield
    pdf.move_down(opts[:bottom_margin]) if opts.key?(:bottom_margin)
  end

  def escape_tags(value)
    # only disable html tags, but do not replace html entities
    value.to_s.gsub("<", "&lt;").gsub(">", "&gt;")
  end

  def make_link_anchor(anchor, caption)
    "<link anchor=\"#{anchor}\">#{caption}</link>"
  end

  def make_link_href(href, caption)
    "<link href=\"#{href}\">#{caption}</link>"
  end

  def link_target_at_current_y(id)
    pdf_dest = pdf.dest_xyz(0, pdf.y)
    pdf.add_dest(id.to_s, pdf_dest)
  end

  def pdf_table_auto_widths(data, column_widths, options, &)
    return if data.empty?

    pdf.table(data, options.merge({ width: pdf.bounds.width }), &)
  rescue Prawn::Errors::CannotFit
    pdf_table_fixed_widths(data, column_widths, options, &)
  end

  def pdf_table_fixed_widths(data, column_widths, options, &)
    pdf.table(data, options.merge({ column_widths: }), &) unless data.empty?
  end

  def draw_horizontal_line(top, left, right, height, color)
    previous_color = pdf.stroke_color
    previous_line_width = pdf.line_width
    @pdf.stroke do
      pdf.stroke_color = color if color
      pdf.line_width = height
      pdf.horizontal_line left, right, at: top
    end
    pdf.stroke_color = previous_color
    pdf.line_width = previous_line_width
  end

  def text_column?(column)
    column.is_a?(Queries::WorkPackages::Selects::CustomFieldSelect) &&
      %w(string text).include?(column.custom_field.field_format)
  end

  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end

  def api_url_helpers
    API::V3::Utilities::PathHelper::ApiV3Path
  end

  def make_group_label(group)
    if group.blank?
      I18n.t(:label_none_parentheses)
    elsif group.is_a? Array
      group.join(", ")
    else
      group.to_s
    end
  end

  def with_cover?
    false
  end

  def get_column_value(work_package, column_name)
    formatter = wp_formatter_for(column_name, :pdf)
    formatter.format(work_package)
  end

  def get_formatted_value(value, column_name)
    return "" if value.nil?

    formatter = wp_formatter_for(column_name, :pdf)
    formatter.format_value(value, {})
  end

  def wp_formatter_for(column_name, format)
    ::Exports::Register.formatter_for(WorkPackage, column_name, format)
  end

  def hyphenation_enabled
    ActiveModel::Type::Boolean.new.cast(options[:hyphenation])
  end

  def hyphenation_language
    language = options[:hyphenation_language]
    language if hyphenation_enabled && HYPHENATION_LANGUAGES.key?(language)
  end

  def build_pdf_filename(base)
    suffix = "_#{title_datetime}.pdf"
    "#{truncate(sane_filename(base), length: 255 - suffix.length, escape: false)}#{suffix}".tr(" ", "-")
  end

  def export_datetime
    @export_datetime ||= Time.current.in_time_zone(User.current.time_zone)
  end

  def title_datetime
    export_datetime.strftime("%Y-%m-%d_%H-%M")
  end

  def footer_date
    format_date(export_datetime)
  end

  def current_page_nr
    pdf.page_number + @page_count - (with_cover? ? 1 : 0)
  end

  def total_page_nr
    @total_page_nr - (with_cover? ? 1 : 0) if @total_page_nr
  end

  def write_horizontal_line(y_position, height, color, left_padding: 0)
    draw_horizontal_line(
      y_position,
      pdf.bounds.left + left_padding, pdf.bounds.right,
      height, color
    )
  end

  def start_new_page_if_needed
    is_first_on_page = pdf.bounds.absolute_top - pdf.y < 10
    pdf.start_new_page unless is_first_on_page
  end

  # Prawn table does not support inline formatting other than inline HTML formatting, so we have to convert the styling
  def prawn_table_cell_inline_formatting_data(text, style) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    value = text || ""
    value = "<link href=\"#{style[:link]}\">#{value}</link>" if style.key?(:link)
    value = "<link anchor=\"#{style[:anchor]}\">#{value}</link>" if style.key?(:anchor)
    value = "<color rgb=\"#{style[:color]}\">#{value}</color>" if style.include?(:color)
    value = "<font size=\"#{style[:size]}\">#{value}</font>" if style.key?(:size)
    value = "<font character_spacing=\"#{style[:character_spacing]}\">#{value}</font>" if style.key?(:character_spacing)
    value = "<font name=\"#{style[:font]}\">#{value}</font>" if style.key?(:font)
    prawn_table_cell_inline_font_styles(value, style[:styles] || [])
  end

  # Prawn table does not support inline formatting other than inline HTML formatting, so we have to convert the styles
  def prawn_table_cell_inline_font_styles(text, styles)
    value = text || ""
    value = "<b>#{value}</b>" if styles.include?(:bold)
    value = "<i>#{value}</i>" if styles.include?(:italic)
    value = "<u>#{value}</u>" if styles.include?(:underline)
    value = "<strikethrough>#{value}</strikethrough>" if styles.include?(:strikethrough)
    value = "<sub>#{value}</sub>" if styles.include?(:sub)
    value = "<sup>#{value}</sup>" if styles.include?(:sup)
    value
  end

  def prawn_draw_horizontal_border(color, width, left, right, at_y)
    pdf.save_graphics_state do
      pdf.stroke_color color if color
      pdf.line_width width if width
      pdf.stroke_horizontal_line left, right, at: at_y
    end
  end

  def prawn_draw_vertical_border(color, width, bottom, top, at_y)
    pdf.save_graphics_state do
      pdf.stroke_color color if color
      pdf.line_width width if width
      pdf.stroke_vertical_line bottom, top, at: at_y
    end
  end

  def prawn_draw_text_box(text_fragments, text_style, margin_style, padding_style, border_style)
    with_margin(margin_style) do
      pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
        with_padding(padding_style) do
          pdf.formatted_text(text_fragments, text_style)
        end
        prawn_draw_box_borders(pdf.bounds, border_style)
      end
    end
  end

  def prawn_draw_box_borders(bounds, border_style) # rubocop:disable Metrics/AbcSize
    borders = border_style[:borders]
    colors = border_style[:border_colors]
    widths = border_style[:border_widths]
    prawn_draw_horizontal_border(colors[0], widths[0], bounds.left, bounds.right, bounds.top) if borders.include?(:top)
    prawn_draw_vertical_border(colors[1], widths[1], bounds.bottom, bounds.top, bounds.right) if borders.include?(:right)
    prawn_draw_horizontal_border(colors[2], widths[2], bounds.left, bounds.right, bounds.bottom) if borders.include?(:bottom)
    prawn_draw_vertical_border(colors[3], widths[3], bounds.bottom, bounds.top, bounds.left) if borders.include?(:left)
  end

  def write_optional_page_break(threshold: styles.page_break_threshold)
    space_from_bottom = pdf.y - pdf.bounds.bottom
    if space_from_bottom < threshold
      pdf.start_new_page
    end
  end

  def make_link_href_cell(href, caption)
    "<color rgb='#{styles.link_color}'>#{make_link_href(href, caption)}</color>"
  end

  def get_id_column_cell(work_package)
    href = url_helpers.work_package_url(work_package)
    make_link_href_cell(href, work_package.display_id)
  end

  def get_subject_column_cell(work_package, value)
    make_link_anchor(work_package.id, escape_tags(value))
  end

  def prawn_color(color)
    color&.hexcode&.sub("#", "") || "F0F0F0"
  end

  def status_prawn_color(status)
    prawn_color(status&.color)
  end

  def wp_status_prawn_color(work_package)
    status_prawn_color(work_package.status)
  end

  def add_pdf_table_anchors(prawn_table)
    # prawn table does not support anchors, so we have to add them manually,
    # @see `lib/open_project/patches/prawn_table_cell.rb` for cell_id attribute
    prawn_table.before_rendering_page do |cells|
      cells.each do |cell|
        if cell.respond_to?(:cell_id) && cell.cell_id.present?
          pdf_dest = @pdf.dest_xyz(@pdf.bounds.absolute_left, @pdf.y + cell.y)
          @pdf.add_dest(cell.cell_id, pdf_dest)
        end
      end
    end
  end

  def get_cf_link_cell(custom_url)
    make_link_href_cell(custom_url.to_s, custom_url.to_s)
  end

  def get_value_cell_by_column(work_package, column_name, format_subject)
    return "" unless allowed_to_view_attribute?(work_package, column_name)

    value = get_column_value(work_package, column_name)
    return get_cf_link_cell(value) if value.is_a?(::Exports::Formatters::LinkFormatter)
    return get_id_column_cell(work_package) if column_name == :id
    return get_subject_column_cell(work_package, value) if format_subject && column_name == :subject

    escape_tags(value)
  end
end
