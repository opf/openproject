#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module WorkPackage::PDFExport::Common
  include Redmine::I18n
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper
  include CustomFieldsHelper
  include OpenProject::TextFormatting

  private

  def get_pdf(_language)
    ::WorkPackage::PDFExport::View.new(current_language)
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
           mime_type: 'application/pdf'
  end

  def error(message)
    raise ::Exports::ExportError.new message
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

  def write_optional_page_break
    space_from_bottom = pdf.y - pdf.bounds.bottom
    if space_from_bottom < styles.page_break_threshold
      pdf.start_new_page
    end
  end

  def get_column_value(work_package, column_name)
    formatter = formatter_for(column_name, :pdf)
    formatter.format(work_package)
  end

  def get_column_value_cell(work_package, column_name)
    value = get_column_value(work_package, column_name)
    return get_id_column_cell(work_package, value) if column_name == :id
    return get_subject_column_cell(work_package, value) if wants_report? && column_name == :subject

    escape_tags(value)
  end

  def get_formatted_value(value, column_name)
    return '' if value.nil?

    formatter = formatter_for(column_name, :pdf)
    formatter.format_value(value, {})
  end

  def escape_tags(value)
    # only disable html tags, but do not replace html entities
    value.to_s.gsub('<', '&lt;').gsub('>', '&gt;')
  end

  def get_id_column_cell(work_package, value)
    href = url_helpers.work_package_url(work_package)
    make_link_href_cell(href, value)
  end

  def get_subject_column_cell(work_package, value)
    make_link_anchor(work_package.id, escape_tags(value))
  end

  def make_link_href_cell(href, caption)
    "<color rgb='#{styles.link_color}'><link href='#{href}'>#{caption}</link></color>"
  end

  def make_link_anchor(anchor, caption)
    "<link anchor=\"#{anchor}\">#{caption}</link>"
  end

  def link_target_at_current_y(id)
    pdf_dest = pdf.dest_xyz(0, pdf.y)
    pdf.add_dest(id.to_s, pdf_dest)
  end

  def pdf_table_auto_widths(data, column_widths, options, &)
    return if data.empty?

    pdf.table(data, options.merge({ width: pdf.bounds.width }), &)
  rescue Prawn::Errors::CannotFit
    pdf.table(data, options.merge({ column_widths: }), &)
  end

  def draw_text_multiline_left(text:, text_style:, max_left:, top:, max_lines:)
    lines = wrap_to_lines(text, max_left - pdf.bounds.left, text_style, max_lines)
    starting_position = top
    lines.reverse_each do |line|
      starting_position += draw_text_multiline_part(line, text_style, pdf.bounds.left, starting_position)
    end
  end

  def draw_text_multiline_right(text:, text_style:, max_left:, top:, max_lines:)
    lines = wrap_to_lines(text, pdf.bounds.right - max_left, text_style, max_lines)
    starting_position = top
    lines.reverse_each do |line|
      line_width = measure_text_width(line, text_style)
      line_x = pdf.bounds.right - line_width
      starting_position += draw_text_multiline_part(line, text_style, line_x, starting_position)
    end
  end

  def formatted_text_box_measured(formatted_text_array, options)
    features_box = ::Prawn::Text::Formatted::Box.new(formatted_text_array, options.merge({ document: pdf }))
    features_box.render
    features_box.height
  end

  def draw_horizontal_line(top, left, right, height, color)
    pdf.stroke do
      pdf.stroke_color = color
      pdf.line_width = height
      pdf.horizontal_line left, right, at: top
    end
  end

  def draw_styled_text(text, opts)
    color_before = pdf.fill_color
    @pdf.save_font do
      @pdf.font(opts[:font], opts) if opts[:font]
      @pdf.fill_color = opts[:color] if opts[:color]
      @pdf.draw_text(text, opts)
    end
    pdf.fill_color = color_before
  end

  def draw_text_centered(text, text_style, top)
    text_width = measure_text_width(text, text_style)
    text_x = (pdf.bounds.width - text_width) / 2
    draw_styled_text text, text_style.merge({ at: [text_x, top] })
    [text_x, text_width]
  end

  def draw_text_multiline_part(line, text_style, x_position, y_position)
    draw_styled_text line, text_style.merge({ at: [x_position, y_position] })
    measure_text_height(line, text_style)
  end

  def truncate_ellipsis(text, available_width, text_style)
    line = text.dup
    while line.present? && (measure_text_width("#{line}...", text_style) > available_width)
      line = line.chop
    end
    "#{line}..."
  end

  def split_wrapped_lines(text, available_width, text_style)
    split_text = text.dup
    lines = []
    arranger = Prawn::Text::Formatted::Arranger.new(pdf)
    line_wrapper = Prawn::Text::Formatted::LineWrap.new
    until split_text.blank?
      arranger.format_array = [text_style.merge({ text: split_text })]
      single_line = line_wrapper.wrap_line(arranger:, width: available_width, document: pdf)
      lines << single_line
      split_text.slice!(single_line)
    end
    lines
  end

  def wrap_to_lines(text, available_width, text_style, max_lines)
    split_text = text.dup
    title_text_width = measure_text_width(split_text, text_style)
    if title_text_width < available_width
      [split_text]
    else
      lines = split_wrapped_lines(text, available_width, text_style)
      if lines.length > max_lines
        lines[max_lines - 1] = truncate_ellipsis(lines[max_lines - 1], available_width, text_style)
        lines = lines.first(max_lines)
      end
      lines
    end
  end

  def measure_text_width(text, opts)
    @pdf.save_font do
      @pdf.font(opts[:font], opts)
      @pdf.width_of(text, opts)
    end
  end

  def measure_text_height(text, opts)
    @pdf.save_font do
      @pdf.font(opts[:font], opts)
      @pdf.height_of(text, opts)
    end
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
      group.join(', ')
    else
      group.to_s
    end
  end

  def get_total_sums
    query.display_sums? ? (query.results.all_total_sums || {}) : {}
  end

  def get_group_sums(group)
    @group_sums ||= query.results.all_group_sums
    @group_sums[group] || {}
  end

  def get_groups
    query.results.work_package_count_by_group
         .select { |_, count| count > 0 }
         .map { |group, _| group }
  end

  def wants_report?
    options[:show_report]
  end

  def with_cover?
    false
  end

  def with_sums_table?
    query.display_sums?
  end

  def with_attachments?
    options[:show_images]
  end

  def build_pdf_filename(base)
    suffix = "_#{title_datetime}.pdf"
    "#{truncate(sane_filename(base), length: 255 - suffix.length, escape: false)}#{suffix}".tr(' ', '-')
  end

  def title_datetime
    DateTime.now.strftime('%Y-%m-%d_%H-%M')
  end

  def current_page_nr
    pdf.page_number + @page_count - (with_cover? ? 1 : 0)
  end
end
