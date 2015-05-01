#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rfpdf/fpdf'
require 'tcpdf'

module WorkPackage::PdfExporter
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  # Returns a PDF string of a list of work_packages
  def pdf(work_packages, project, query, results, options = {})
    if  current_language.to_s.downcase == 'ko'    ||
        current_language.to_s.downcase == 'ja'    ||
        current_language.to_s.downcase == 'zh'    ||
        current_language.to_s.downcase == 'zh-tw' ||
        current_language.to_s.downcase == 'th'
      pdf = IFPDF.new(current_language)
    else
      pdf = ITCPDF.new(current_language)
    end
    title = query.new_record? ? l(:label_work_package_plural) : query.name
    title = "#{project} - #{title}" if project
    pdf.SetTitle(title)
    pdf.alias_nb_pages
    pdf.footer_date = format_date(Date.today)
    pdf.SetAutoPageBreak(false)
    pdf.AddPage('L')

    # Landscape A4 = 210 x 297 mm
    page_height = 210
    page_width = 297
    right_margin = 10
    bottom_margin = 20
    row_height = 5

    # column widths
    table_width = page_width - right_margin - 10  # fixed left margin
    col_width = []
    unless query.columns.empty?
      col_width = query.columns.map do |c|
        (c.name == :subject || (c.is_a?(QueryCustomFieldColumn) && ['string', 'text'].include?(c.custom_field.field_format))) ? 4.0 : 1.0
      end
      ratio = table_width / col_width.reduce(:+)
      col_width = col_width.map { |w| w * ratio }
    end

    # title
    pdf.SetFontStyle('B', 11)
    pdf.RDMCell(190, 10, title)
    pdf.Ln

    # headers
    pdf.SetFontStyle('B', 8)
    pdf.SetFillColor(230, 230, 230)
    query.columns.each_with_index do |column, i|
      pdf.RDMCell(col_width[i], row_height, column.caption, 1, 0, 'L', 1)
    end
    pdf.Ln

    # rows
    pdf.SetFontStyle('', 8)
    pdf.SetFillColor(255, 255, 255)
    previous_group = false
    work_packages.each do |work_package|
      if query.grouped? && (group = query.group_by_column.value(work_package)) != previous_group
        pdf.SetFontStyle('B', 9)
        pdf.RDMCell(277, row_height,
                    (group.blank? ? 'None' : group.to_s) + " (#{results.work_package_count_for(group)})",
                    1, 1, 'L')
        pdf.SetFontStyle('', 8)
        previous_group = group
      end

      # fetch all the row values
      col_values = query.columns.map do |column|
        s = if column.is_a?(QueryCustomFieldColumn)
              cv = work_package.custom_values.detect { |v| v.custom_field_id == column.custom_field.id }
              show_value(cv)
            else
              value = work_package.send(column.name)
              if value.is_a?(Date)
                format_date(value)
              elsif value.is_a?(Time)
                format_time(value)
              else
                value
              end
            end
        s.to_s
      end

      # render it off-page to find the max height used
      base_x = pdf.GetX
      base_y = pdf.GetY
      pdf.SetY(2 * page_height)
      max_height = pdf_write_cells(pdf, col_values, col_width, row_height)
      description_height = 0
      if options[:show_descriptions]
        description_height = pdf_write_cells(pdf,
                                             [work_package.description.to_s],
                                             [table_width / 2],
                                             row_height)
      end
      pdf.SetXY(base_x, base_y)

      # make new page if it doesn't fit on the current one
      space_left = page_height - base_y - bottom_margin
      if max_height + description_height > space_left
        pdf.AddPage('L')
        base_x = pdf.GetX
        base_y = pdf.GetY
      end

      # write the cells on page
      pdf_write_cells(pdf, col_values, col_width, row_height)
      pdf_draw_borders(pdf, base_x, base_y, base_y + max_height, col_width)

      # description
      if options[:show_descriptions]
        pdf.SetXY(base_x, base_y + max_height)
        pdf_write_cells(pdf,
                        [work_package.description.to_s],
                        [table_width / 2],
                        row_height)
        pdf_draw_borders(pdf,
                         base_x,
                         base_y + max_height,
                         base_y + max_height + description_height,
                         [table_width])
        pdf.SetY(base_y + max_height + description_height)
      else
        pdf.SetY(base_y + max_height)
      end
    end

    if work_packages.size == Setting.work_packages_export_limit.to_i
      pdf.SetFontStyle('B', 10)
      pdf.RDMCell(0, row_height, '...')
    end
    pdf.Output
  end

  # Returns a PDF string of a single work_package
  def work_package_to_pdf(work_package)
    if  current_language.to_s.downcase == 'ko'    ||
        current_language.to_s.downcase == 'ja'    ||
        current_language.to_s.downcase == 'zh'    ||
        current_language.to_s.downcase == 'zh-tw' ||
        current_language.to_s.downcase == 'th'
      pdf = IFPDF.new(current_language)
    else
      pdf = ITCPDF.new(current_language)
    end
    pdf.SetTitle("#{work_package.project} - ##{work_package.type} #{work_package.id}")
    pdf.alias_nb_pages
    pdf.footer_date = format_date(Date.today)
    pdf.AddPage

    pdf.SetFontStyle('B', 11)
    pdf.RDMMultiCell(190, 5, "#{work_package.project} - #{work_package.type} # #{work_package.id}: #{work_package.subject}")
    pdf.Ln

    y0 = pdf.GetY

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:status) + ':', 'LT')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.status.to_s, 'RT')
    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:priority) + ':', 'LT')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.priority.to_s, 'RT')
    pdf.Ln

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:author) + ':', 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.author.to_s, 'R')
    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:category) + ':', 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.category.to_s, 'R')
    pdf.Ln

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:created_at) + ':', 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, format_date(work_package.created_at), 'R')
    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:assigned_to) + ':', 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, work_package.assigned_to.to_s, 'R')
    pdf.Ln

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:updated_at) + ':', 'LB')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, format_date(work_package.updated_at), 'RB')
    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:due_date) + ':', 'LB')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, format_date(work_package.due_date), 'RB')
    pdf.Ln

    for custom_value in work_package.custom_field_values
      pdf.SetFontStyle('B', 9)
      pdf.RDMCell(35, 5, custom_value.custom_field.name + ':', 'L')
      pdf.SetFontStyle('', 9)
      pdf.RDMMultiCell(155, 5, (show_value custom_value), 'R')
    end

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(35, 5, WorkPackage.human_attribute_name(:description) + ':')
    pdf.SetFontStyle('', 9)
    pdf.RDMMultiCell(155, 5, work_package.description.to_s, 'BR')

    pdf.Line(pdf.GetX, y0, pdf.GetX, pdf.GetY)
    pdf.Line(pdf.GetX, pdf.GetY, pdf.GetX + 190, pdf.GetY)
    pdf.Ln

    if work_package.changesets.any? && User.current.allowed_to?(:view_changesets, work_package.project)
      pdf.SetFontStyle('B', 9)
      pdf.RDMCell(190, 5, l(:label_associated_revisions), 'B')
      pdf.Ln
      for changeset in work_package.changesets
        pdf.SetFontStyle('B', 8)
        pdf.RDMCell(190, 5, format_time(changeset.committed_on) + ' - ' + changeset.author.to_s)
        pdf.Ln
        unless changeset.comments.blank?
          pdf.SetFontStyle('', 8)
          pdf.RDMMultiCell(190, 5, changeset.comments.to_s)
        end
        pdf.Ln
      end
    end

    pdf.SetFontStyle('B', 9)
    pdf.RDMCell(190, 5, l(:label_history), 'B')
    pdf.Ln
    for journal in work_package.journals.find(:all, include: [:user], order: "#{Journal.table_name}.created_at ASC")
      next if journal.initial?
      pdf.SetFontStyle('B', 8)
      pdf.RDMCell(190, 5, format_time(journal.created_at) + ' - ' + journal.user.name)
      pdf.Ln
      pdf.SetFontStyle('I', 8)
      for detail in journal.details
        pdf.RDMMultiCell(190, 5, '- ' + journal.render_detail(detail, no_html: true, only_path: false))
        pdf.Ln
      end
      if journal.notes?
        pdf.Ln unless journal.details.empty?
        pdf.SetFontStyle('', 8)
        pdf.RDMMultiCell(190, 5, journal.notes.to_s)
      end
      pdf.Ln
    end

    if work_package.attachments.any?
      pdf.SetFontStyle('B', 9)
      pdf.RDMCell(190, 5, l(:label_attachment_plural), 'B')
      pdf.Ln
      for attachment in work_package.attachments
        pdf.SetFontStyle('', 8)
        pdf.RDMCell(80, 5, attachment.filename)
        pdf.RDMCell(20, 5, number_to_human_size(attachment.filesize), 0, 0, 'R')
        pdf.RDMCell(25, 5, format_date(attachment.created_on), 0, 0, 'R')
        pdf.RDMCell(65, 5, attachment.author.name, 0, 0, 'R')
        pdf.Ln
      end
    end
    pdf.Output
  end

  private

  # Renders MultiCells and returns the maximum height used
  def pdf_write_cells(pdf, col_values, col_widths, row_height)
    base_y = pdf.GetY
    max_height = row_height
    col_values.each_with_index do |_column, i|
      col_x = pdf.GetX
      pdf.RDMMultiCell(col_widths[i], row_height, col_values[i], 'T', 'L', 1)
      max_height = (pdf.GetY - base_y) if (pdf.GetY - base_y) > max_height
      pdf.SetXY(col_x + col_widths[i], base_y)
    end
    max_height
  end

  # Draw lines to close the row (MultiCell border drawing in not uniform)
  def pdf_draw_borders(pdf, top_x, top_y, lower_y, col_widths)
    col_x = top_x
    pdf.Line(col_x, top_y, col_x, lower_y)    # id right border
    col_widths.each do |width|
      col_x += width
      pdf.Line(col_x, top_y, col_x, lower_y)  # columns right border
    end
    pdf.Line(top_x, top_y, top_x, lower_y)    # left border
    pdf.Line(top_x, lower_y, col_x, lower_y)  # bottom border
  end

  class ITCPDF < TCPDF
    include Redmine::I18n
    attr_accessor :footer_date

    def initialize(lang)
      super()
      set_language_if_valid lang
      @font_for_content = 'FreeSans'
      @font_for_footer  = 'FreeSans'
      SetCreator(OpenProject::Info.app_name)
      SetFont(@font_for_content)
    end

    def SetFontStyle(style, size)
      SetFont(@font_for_content, style, size)
    end

    def SetTitle(txt)
      txt = begin
        utf16txt = txt.to_s.encode('UTF-16BE', 'UTF-8')
        hextxt = '<FEFF'  # FEFF is BOM
        hextxt << utf16txt.unpack('C*').map { |x| sprintf('%02X', x) }.join
        hextxt << '>'
      rescue
        txt
      end || ''
      super(txt)
    end

    def textstring(s)
      # Format a text string
      if s =~ /\A</  # This means the string is hex-dumped.
        return s
      else
        return '(' + escape(s) + ')'
      end
    end

    alias RDMCell Cell
    alias RDMMultiCell MultiCell

    def Footer
      SetFont(@font_for_footer, 'I', 8)
      SetY(-15)
      SetX(15)
      RDMCell(0, 5, @footer_date, 0, 0, 'L')
      SetY(-15)
      SetX(-30)
      RDMCell(0, 5, PageNo().to_s + '/{nb}', 0, 0, 'C')
    end
  end

  class IFPDF < FPDF
    include Redmine::I18n
    attr_accessor :footer_date

    def initialize(lang)
      super()
      set_language_if_valid lang

      @font_for_content = 'Arial'
      @font_for_footer  = 'Helvetica'

      SetCreator(OpenProject::Info.app_name)
      SetFont(@font_for_content)
    end

    def SetFontStyle(style, size)
      SetFont(@font_for_content, style, size)
    end

    def SetTitle(txt)
      txt = begin
        utf16txt = txt.to_s.encode('UTF-16BE', 'UTF-8')
        hextxt = '<FEFF'  # FEFF is BOM
        hextxt << utf16txt.unpack('C*').map { |x| sprintf('%02X', x) }.join
        hextxt << '>'
      rescue
        txt
      end || ''
      super(txt)
    end

    def textstring(s)
      # Format a text string
      if s =~ /\A</  # This means the string is hex-dumped.
        return s
      else
        return '(' + escape(s) + ')'
      end
    end

    def fix_text_encoding(txt)
      # these quotation marks are not correctly rendered in the pdf
      txt = txt.gsub(/[â€œâ€�]/, '"') if txt
      txt = begin
        # 0x5c char handling
        txtar = txt.split('\\')
        txtar << '' if txt[-1] == ?\\
        txtar.map { |x| x.encode(l(:general_pdf_encoding), 'UTF-8') }.join('\\').gsub(/\\/, '\\\\\\\\')
      rescue
        txt
      end || ''
      txt
    end

    def RDMCell(w, h = 0, txt = '', border = 0, ln = 0, align = '', fill = 0, link = '')
      Cell(w, h, fix_text_encoding(txt), border, ln, align, fill, link)
    end

    def RDMMultiCell(w, h = 0, txt = '', border = 0, align = '', fill = 0)
      MultiCell(w, h, fix_text_encoding(txt), border, align, fill)
    end

    def Footer
      SetFont(@font_for_footer, 'I', 8)
      SetY(-15)
      SetX(15)
      RDMCell(0, 5, @footer_date, 0, 0, 'L')
      SetY(-15)
      SetX(-30)
      RDMCell(0, 5, PageNo().to_s + '/{nb}', 0, 0, 'C')
    end
    alias alias_nb_pages AliasNbPages
  end
end
