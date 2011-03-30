# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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

require 'iconv'
require 'rfpdf/fpdf'
require 'fpdf/chinese'
require 'fpdf/japanese'
require 'fpdf/korean'

module Redmine
  module Export
    module PDF
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::NumberHelper
      
      class ITCPDF < TCPDF
        include Redmine::I18n
        attr_accessor :footer_date
        
        def initialize(lang)
          super()
          set_language_if_valid lang
          @font_for_content = 'FreeSans'
          @font_for_footer = 'FreeSans'              
          SetCreator(Redmine::Info.app_name)
          SetFont(@font_for_content)
        end
        
        def SetFontStyle(style, size)
          SetFont(@font_for_content, style, size)
        end
        
        def SetTitle(txt)
          txt = begin
            utf16txt = Iconv.conv('UTF-16BE', 'UTF-8', txt)
            hextxt = "<FEFF"  # FEFF is BOM
            hextxt << utf16txt.unpack("C*").map {|x| sprintf("%02X",x) }.join
            hextxt << ">"
          rescue
            txt
          end || ''
          super(txt)
        end
    
        def textstring(s)
          # Format a text string
          if s =~ /^</  # This means the string is hex-dumped.
            return s
          else
            return '('+escape(s)+')'
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
          case current_language.to_s.downcase
          when 'ko'
            extend(PDF_Korean)
            AddUHCFont()
            @font_for_content = 'UHC'
            @font_for_footer = 'UHC'
          when 'ja'
            extend(PDF_Japanese)
            AddSJISFont()
            @font_for_content = 'SJIS'
            @font_for_footer = 'SJIS'
          when 'zh'
            extend(PDF_Chinese)
            AddGBFont()
            @font_for_content = 'GB'
            @font_for_footer = 'GB'
          when 'zh-tw'
            extend(PDF_Chinese)
            AddBig5Font()
            @font_for_content = 'Big5'
            @font_for_footer = 'Big5'
          else
            @font_for_content = 'Arial'
            @font_for_footer = 'Helvetica'              
          end
          SetCreator(Redmine::Info.app_name)
          SetFont(@font_for_content)
        end
        
        def SetFontStyle(style, size)
          SetFont(@font_for_content, style, size)
        end
        
        def SetTitle(txt)
          txt = begin
            utf16txt = Iconv.conv('UTF-16BE', 'UTF-8', txt)
            hextxt = "<FEFF"  # FEFF is BOM
            hextxt << utf16txt.unpack("C*").map {|x| sprintf("%02X",x) }.join
            hextxt << ">"
          rescue
            txt
          end || ''
          super(txt)
        end
    
        def textstring(s)
          # Format a text string
          if s =~ /^</  # This means the string is hex-dumped.
            return s
          else
            return '('+escape(s)+')'
          end
        end
          
        def fix_text_encoding(txt)
          @ic ||= Iconv.new(l(:general_pdf_encoding), 'UTF-8')
          # these quotation marks are not correctly rendered in the pdf
          txt = txt.gsub(/[â€œâ€�]/, '"') if txt
          txt = begin
            # 0x5c char handling
            txtar = txt.split('\\')
            txtar << '' if txt[-1] == ?\\
            txtar.collect {|x| @ic.iconv(x)}.join('\\').gsub(/\\/, "\\\\\\\\")
          rescue
            txt
          end || ''
            return txt
        end
        
        def RDMCell(w,h=0,txt='',border=0,ln=0,align='',fill=0,link='')
            Cell(w,h,fix_text_encoding(txt),border,ln,align,fill,link)
        end
        
        def RDMMultiCell(w,h=0,txt='',border=0,align='',fill=0)
            MultiCell(w,h,fix_text_encoding(txt),border,align,fill)
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

      # Returns a PDF string of a list of issues
      def issues_to_pdf(issues, project, query)
        pdf = IFPDF.new(current_language)

        title = query.new_record? ? l(:label_issue_plural) : query.name
        title = "#{project} - #{title}" if project
        pdf.SetTitle(title)
        pdf.alias_nb_pages
        pdf.footer_date = format_date(Date.today)
        pdf.AddPage("L")
        
        row_height = 6
        col_width = []
        unless query.columns.empty?
          col_width = query.columns.collect {|column| column.name == :subject ? 4.0 : 1.0 }
          ratio = 262.0 / col_width.inject(0) {|s,w| s += w}
          col_width = col_width.collect {|w| w * ratio}
        end
        
        # title
        pdf.SetFontStyle('B',11)    
        pdf.RDMCell(190,10, title)
        pdf.Ln
        
        # headers
        pdf.SetFontStyle('B',8)
        pdf.SetFillColor(230, 230, 230)
        pdf.RDMCell(15, row_height, "#", 1, 0, 'L', 1)
        query.columns.each_with_index do |column, i|
          pdf.RDMCell(col_width[i], row_height, column.caption, 1, 0, 'L', 1)
        end
        pdf.Ln
        
        # rows
        pdf.SetFontStyle('',8)
        pdf.SetFillColor(255, 255, 255)
        previous_group = false
        issues.each do |issue|
          if query.grouped? && (group = query.group_by_column.value(issue)) != previous_group
            pdf.SetFontStyle('B',9)
            pdf.RDMCell(277, row_height, 
              (group.blank? ? 'None' : group.to_s) + " (#{query.issue_count_by_group[group]})",
              1, 1, 'L')
            pdf.SetFontStyle('',8)
            previous_group = group
          end
          pdf.RDMCell(15, row_height, issue.id.to_s, 1, 0, 'L', 1)
          query.columns.each_with_index do |column, i|
            s = if column.is_a?(QueryCustomFieldColumn)
              cv = issue.custom_values.detect {|v| v.custom_field_id == column.custom_field.id}
              show_value(cv)
            else
              value = issue.send(column.name)
              if value.is_a?(Date)
                format_date(value)
              elsif value.is_a?(Time)
                format_time(value)
              else
                value
              end
            end
            pdf.RDMCell(col_width[i], row_height, s.to_s, 1, 0, 'L', 1)
          end
          pdf.Ln
        end
        if issues.size == Setting.issues_export_limit.to_i
          pdf.SetFontStyle('B',10)
          pdf.RDMCell(0, row_height, '...')
        end
        pdf.Output
      end

      # Returns a PDF string of a single issue
      def issue_to_pdf(issue)
        pdf = IFPDF.new(current_language)
        pdf.SetTitle("#{issue.project} - ##{issue.tracker} #{issue.id}")
        pdf.alias_nb_pages
        pdf.footer_date = format_date(Date.today)
        pdf.AddPage
        
        pdf.SetFontStyle('B',11)    
        pdf.RDMCell(190,10, "#{issue.project} - #{issue.tracker} # #{issue.id}: #{issue.subject}")
        pdf.Ln
        
        y0 = pdf.GetY
        
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_status) + ":","LT")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(60,5, issue.status.to_s,"RT")
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_priority) + ":","LT")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(60,5, issue.priority.to_s,"RT")        
        pdf.Ln
        
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_author) + ":","L")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(60,5, issue.author.to_s,"R")
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_category) + ":","L")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(60,5, issue.category.to_s,"R")
        pdf.Ln   
        
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_created_on) + ":","L")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(60,5, format_date(issue.created_on),"R")
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_assigned_to) + ":","L")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(60,5, issue.assigned_to.to_s,"R")
        pdf.Ln
        
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_updated_on) + ":","LB")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(60,5, format_date(issue.updated_on),"RB")
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_due_date) + ":","LB")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(60,5, format_date(issue.due_date),"RB")
        pdf.Ln
        
        for custom_value in issue.custom_field_values
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(35,5, custom_value.custom_field.name + ":","L")
          pdf.SetFontStyle('',9)
          pdf.RDMMultiCell(155,5, (show_value custom_value),"R")
        end
        
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_subject) + ":","LTB")
        pdf.SetFontStyle('',9)
        pdf.RDMCell(155,5, issue.subject,"RTB")
        pdf.Ln    
        
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35,5, l(:field_description) + ":")
        pdf.SetFontStyle('',9)
        pdf.RDMMultiCell(155,5, issue.description.to_s,"BR")
        
        pdf.Line(pdf.GetX, y0, pdf.GetX, pdf.GetY)
        pdf.Line(pdf.GetX, pdf.GetY, 170, pdf.GetY)
        pdf.Ln
        
        if issue.changesets.any? && User.current.allowed_to?(:view_changesets, issue.project)
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(190,5, l(:label_associated_revisions), "B")
          pdf.Ln
          for changeset in issue.changesets
            pdf.SetFontStyle('B',8)
            pdf.RDMCell(190,5, format_time(changeset.committed_on) + " - " + changeset.author.to_s)
            pdf.Ln
            unless changeset.comments.blank?
              pdf.SetFontStyle('',8)
              pdf.RDMMultiCell(190,5, changeset.comments.to_s)
            end   
            pdf.Ln
          end
        end
        
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(190,5, l(:label_history), "B")
        pdf.Ln  
        for journal in issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
          pdf.SetFontStyle('B',8)
          pdf.RDMCell(190,5, format_time(journal.created_on) + " - " + journal.user.name)
          pdf.Ln
          pdf.SetFontStyle('I',8)
          for detail in journal.details
            pdf.RDMCell(190,5, "- " + show_detail(detail, true))
            pdf.Ln
          end
          if journal.notes?
            pdf.SetFontStyle('',8)
            pdf.RDMMultiCell(190,5, journal.notes.to_s)
          end   
          pdf.Ln
        end
        
        if issue.attachments.any?
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(190,5, l(:label_attachment_plural), "B")
          pdf.Ln
          for attachment in issue.attachments
            pdf.SetFontStyle('',8)
            pdf.RDMCell(80,5, attachment.filename)
            pdf.RDMCell(20,5, number_to_human_size(attachment.filesize),0,0,"R")
            pdf.RDMCell(25,5, format_date(attachment.created_on),0,0,"R")
            pdf.RDMCell(65,5, attachment.author.name,0,0,"R")
            pdf.Ln
          end
        end
        pdf.Output
      end

    end
  end
end
