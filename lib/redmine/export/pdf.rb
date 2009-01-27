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
require 'rfpdf/chinese'

module Redmine
  module Export
    module PDF
      include ActionView::Helpers::NumberHelper
      
      class IFPDF < FPDF
        include GLoc
        attr_accessor :footer_date
        
        def initialize(lang)
          super()
          set_language_if_valid lang
          case current_language.to_s
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
          
        def Cell(w,h=0,txt='',border=0,ln=0,align='',fill=0,link='')
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
          super w,h,txt,border,ln,align,fill,link
        end
        
        def Footer
          SetFont(@font_for_footer, 'I', 8)
          SetY(-15)
          SetX(15)
          Cell(0, 5, @footer_date, 0, 0, 'L')
          SetY(-15)
          SetX(-30)
          Cell(0, 5, PageNo().to_s + '/{nb}', 0, 0, 'C')
        end
      end
      
      # Returns a PDF string of a list of issues
      def issues_to_pdf(issues, project)
        pdf = IFPDF.new(current_language)
        title = project ? "#{project} - #{l(:label_issue_plural)}" : "#{l(:label_issue_plural)}"
        pdf.SetTitle(title)
        pdf.AliasNbPages
        pdf.footer_date = format_date(Date.today)
        pdf.AddPage("L")
        row_height = 7
        
        # title
        pdf.SetFontStyle('B',11)    
        pdf.Cell(190,10, title)
        pdf.Ln
        
        # headers
        pdf.SetFontStyle('B',10)
        pdf.SetFillColor(230, 230, 230)
        pdf.Cell(15, row_height, "#", 0, 0, 'L', 1)
        pdf.Cell(30, row_height, l(:field_tracker), 0, 0, 'L', 1)
        pdf.Cell(30, row_height, l(:field_status), 0, 0, 'L', 1)
        pdf.Cell(30, row_height, l(:field_priority), 0, 0, 'L', 1)
        pdf.Cell(40, row_height, l(:field_assigned_to), 0, 0, 'L', 1)
        pdf.Cell(25, row_height, l(:field_updated_on), 0, 0, 'L', 1)
        pdf.Cell(0, row_height, l(:field_subject), 0, 0, 'L', 1)
        pdf.Line(10, pdf.GetY, 287, pdf.GetY)
        pdf.Ln
        pdf.Line(10, pdf.GetY, 287, pdf.GetY)
        pdf.SetY(pdf.GetY() + 1)
        
        # rows
        pdf.SetFontStyle('',9)
        pdf.SetFillColor(255, 255, 255)
        issues.each do |issue|   
          pdf.Cell(15, row_height, issue.id.to_s, 0, 0, 'L', 1)
          pdf.Cell(30, row_height, issue.tracker.name, 0, 0, 'L', 1)
          pdf.Cell(30, row_height, issue.status.name, 0, 0, 'L', 1)
          pdf.Cell(30, row_height, issue.priority.name, 0, 0, 'L', 1)
          pdf.Cell(40, row_height, issue.assigned_to ? issue.assigned_to.to_s : '', 0, 0, 'L', 1)
          pdf.Cell(25, row_height, format_date(issue.updated_on), 0, 0, 'L', 1)
          pdf.MultiCell(0, row_height, (project == issue.project ? issue.subject : "#{issue.project} - #{issue.subject}"))
          pdf.Line(10, pdf.GetY, 287, pdf.GetY)
          pdf.SetY(pdf.GetY() + 1)
        end
        pdf.Output
      end
      
      # Returns a PDF string of a single issue
      def issue_to_pdf(issue)
        pdf = IFPDF.new(current_language)
        pdf.SetTitle("#{issue.project} - ##{issue.tracker} #{issue.id}")
        pdf.AliasNbPages
        pdf.footer_date = format_date(Date.today)
        pdf.AddPage
        
        pdf.SetFontStyle('B',11)    
        pdf.Cell(190,10, "#{issue.project} - #{issue.tracker} # #{issue.id}: #{issue.subject}")
        pdf.Ln
        
        y0 = pdf.GetY
        
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_status) + ":","LT")
        pdf.SetFontStyle('',9)
        pdf.Cell(60,5, issue.status.to_s,"RT")
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_priority) + ":","LT")
        pdf.SetFontStyle('',9)
        pdf.Cell(60,5, issue.priority.to_s,"RT")        
        pdf.Ln
          
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_author) + ":","L")
        pdf.SetFontStyle('',9)
        pdf.Cell(60,5, issue.author.to_s,"R")
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_category) + ":","L")
        pdf.SetFontStyle('',9)
        pdf.Cell(60,5, issue.category.to_s,"R")
        pdf.Ln   
        
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_created_on) + ":","L")
        pdf.SetFontStyle('',9)
        pdf.Cell(60,5, format_date(issue.created_on),"R")
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_assigned_to) + ":","L")
        pdf.SetFontStyle('',9)
        pdf.Cell(60,5, issue.assigned_to.to_s,"R")
        pdf.Ln
        
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_updated_on) + ":","LB")
        pdf.SetFontStyle('',9)
        pdf.Cell(60,5, format_date(issue.updated_on),"RB")
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_due_date) + ":","LB")
        pdf.SetFontStyle('',9)
        pdf.Cell(60,5, format_date(issue.due_date),"RB")
        pdf.Ln
          
        for custom_value in issue.custom_values
          pdf.SetFontStyle('B',9)
          pdf.Cell(35,5, custom_value.custom_field.name + ":","L")
          pdf.SetFontStyle('',9)
          pdf.MultiCell(155,5, (show_value custom_value),"R")
        end
          
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_subject) + ":","LTB")
        pdf.SetFontStyle('',9)
        pdf.Cell(155,5, issue.subject,"RTB")
        pdf.Ln    
        
        pdf.SetFontStyle('B',9)
        pdf.Cell(35,5, l(:field_description) + ":")
        pdf.SetFontStyle('',9)
        pdf.MultiCell(155,5, @issue.description,"BR")
        
        pdf.Line(pdf.GetX, y0, pdf.GetX, pdf.GetY)
        pdf.Line(pdf.GetX, pdf.GetY, 170, pdf.GetY)
        pdf.Ln
        
        if issue.changesets.any? && User.current.allowed_to?(:view_changesets, issue.project)
          pdf.SetFontStyle('B',9)
          pdf.Cell(190,5, l(:label_associated_revisions), "B")
          pdf.Ln
          for changeset in issue.changesets
            pdf.SetFontStyle('B',8)
            pdf.Cell(190,5, format_time(changeset.committed_on) + " - " + changeset.author.to_s)
            pdf.Ln
            unless changeset.comments.blank?
              pdf.SetFontStyle('',8)
              pdf.MultiCell(190,5, changeset.comments)
            end   
            pdf.Ln
          end
        end
        
        pdf.SetFontStyle('B',9)
        pdf.Cell(190,5, l(:label_history), "B")
        pdf.Ln  
        for journal in issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
          pdf.SetFontStyle('B',8)
          pdf.Cell(190,5, format_time(journal.created_on) + " - " + journal.user.name)
          pdf.Ln
          pdf.SetFontStyle('I',8)
          for detail in journal.details
            pdf.Cell(190,5, "- " + show_detail(detail, true))
            pdf.Ln
          end
          if journal.notes?
            pdf.SetFontStyle('',8)
            pdf.MultiCell(190,5, journal.notes)
          end   
          pdf.Ln
        end
        
        if issue.attachments.any?
          pdf.SetFontStyle('B',9)
          pdf.Cell(190,5, l(:label_attachment_plural), "B")
          pdf.Ln
          for attachment in issue.attachments
            pdf.SetFontStyle('',8)
            pdf.Cell(80,5, attachment.filename)
            pdf.Cell(20,5, number_to_human_size(attachment.filesize),0,0,"R")
            pdf.Cell(25,5, format_date(attachment.created_on),0,0,"R")
            pdf.Cell(65,5, attachment.author.name,0,0,"R")
            pdf.Ln
          end
        end
        pdf.Output
      end
      
      # Returns a PDF string of a gantt chart
      def gantt_to_pdf(gantt, project)
        pdf = IFPDF.new(current_language)
        pdf.SetTitle("#{l(:label_gantt)} #{project}")
        pdf.AliasNbPages
        pdf.footer_date = format_date(Date.today)
        pdf.AddPage("L")
        pdf.SetFontStyle('B',12)
        pdf.SetX(15)
        pdf.Cell(70, 20, project.to_s)
        pdf.Ln
        pdf.SetFontStyle('B',9)
        
        subject_width = 70
        header_heigth = 5
        
        headers_heigth = header_heigth
        show_weeks = false
        show_days = false
        
        if gantt.months < 7
          show_weeks = true
          headers_heigth = 2*header_heigth
          if gantt.months < 3
            show_days = true
            headers_heigth = 3*header_heigth
          end
        end
        
        g_width = 210
        zoom = (g_width) / (gantt.date_to - gantt.date_from + 1)
        g_height = 120
        t_height = g_height + headers_heigth
        
        y_start = pdf.GetY
        
        # Months headers
        month_f = gantt.date_from
        left = subject_width
        height = header_heigth
        gantt.months.times do 
          width = ((month_f >> 1) - month_f) * zoom 
          pdf.SetY(y_start)
          pdf.SetX(left)
          pdf.Cell(width, height, "#{month_f.year}-#{month_f.month}", "LTR", 0, "C")
          left = left + width
          month_f = month_f >> 1
        end  
        
        # Weeks headers
        if show_weeks
          left = subject_width
          height = header_heigth
          if gantt.date_from.cwday == 1
            # gantt.date_from is monday
            week_f = gantt.date_from
          else
            # find next monday after gantt.date_from
            week_f = gantt.date_from + (7 - gantt.date_from.cwday + 1)
            width = (7 - gantt.date_from.cwday + 1) * zoom-1
            pdf.SetY(y_start + header_heigth)
            pdf.SetX(left)
            pdf.Cell(width + 1, height, "", "LTR")
            left = left + width+1
          end
          while week_f <= gantt.date_to
            width = (week_f + 6 <= gantt.date_to) ? 7 * zoom : (gantt.date_to - week_f + 1) * zoom
            pdf.SetY(y_start + header_heigth)
            pdf.SetX(left)
            pdf.Cell(width, height, (width >= 5 ? week_f.cweek.to_s : ""), "LTR", 0, "C")
            left = left + width
            week_f = week_f+7
          end
        end
        
        # Days headers
        if show_days
          left = subject_width
          height = header_heigth
          wday = gantt.date_from.cwday
          pdf.SetFontStyle('B',7)
          (gantt.date_to - gantt.date_from + 1).to_i.times do 
            width = zoom
            pdf.SetY(y_start + 2 * header_heigth)
            pdf.SetX(left)
            pdf.Cell(width, height, day_name(wday).first, "LTR", 0, "C")
            left = left + width
            wday = wday + 1
            wday = 1 if wday > 7
          end
        end
        
        pdf.SetY(y_start)
        pdf.SetX(15)
        pdf.Cell(subject_width+g_width-15, headers_heigth, "", 1)
        
        # Tasks
        top = headers_heigth + y_start
        pdf.SetFontStyle('B',7)
        gantt.events.each do |i|
          pdf.SetY(top)
          pdf.SetX(15)
          
          if i.is_a? Issue
            pdf.Cell(subject_width-15, 5, "#{i.tracker} #{i.id}: #{i.subject}".sub(/^(.{30}[^\s]*\s).*$/, '\1 (...)'), "LR")
          else
            pdf.Cell(subject_width-15, 5, "#{l(:label_version)}: #{i.name}", "LR")
          end
        
          pdf.SetY(top)
          pdf.SetX(subject_width)
          pdf.Cell(g_width, 5, "", "LR")
        
          pdf.SetY(top+1.5)
          
          if i.is_a? Issue
            i_start_date = (i.start_date >= gantt.date_from ? i.start_date : gantt.date_from )
            i_end_date = (i.due_before <= gantt.date_to ? i.due_before : gantt.date_to )
            
            i_done_date = i.start_date + ((i.due_before - i.start_date+1)*i.done_ratio/100).floor
            i_done_date = (i_done_date <= gantt.date_from ? gantt.date_from : i_done_date )
            i_done_date = (i_done_date >= gantt.date_to ? gantt.date_to : i_done_date )
            
            i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
            
            i_left = ((i_start_date - gantt.date_from)*zoom) 
            i_width = ((i_end_date - i_start_date + 1)*zoom)
            d_width = ((i_done_date - i_start_date)*zoom)
            l_width = ((i_late_date - i_start_date+1)*zoom) if i_late_date
            l_width ||= 0
          
            pdf.SetX(subject_width + i_left)
            pdf.SetFillColor(200,200,200)
            pdf.Cell(i_width, 2, "", 0, 0, "", 1)
          
            if l_width > 0
              pdf.SetY(top+1.5)
              pdf.SetX(subject_width + i_left)
              pdf.SetFillColor(255,100,100)
              pdf.Cell(l_width, 2, "", 0, 0, "", 1)
            end 
            if d_width > 0
              pdf.SetY(top+1.5)
              pdf.SetX(subject_width + i_left)
              pdf.SetFillColor(100,100,255)
              pdf.Cell(d_width, 2, "", 0, 0, "", 1)
            end
            
            pdf.SetY(top+1.5)
            pdf.SetX(subject_width + i_left + i_width)
            pdf.Cell(30, 2, "#{i.status} #{i.done_ratio}%")
          else
            i_left = ((i.start_date - gantt.date_from)*zoom) 
            
            pdf.SetX(subject_width + i_left)
            pdf.SetFillColor(50,200,50)
            pdf.Cell(2, 2, "", 0, 0, "", 1) 
        
            pdf.SetY(top+1.5)
            pdf.SetX(subject_width + i_left + 3)
            pdf.Cell(30, 2, "#{i.name}")
          end
          
          top = top + 5
          pdf.SetDrawColor(200, 200, 200)
          pdf.Line(15, top, subject_width+g_width, top)
          if pdf.GetY() > 180
            pdf.AddPage("L")
            top = 20
            pdf.Line(15, top, subject_width+g_width, top)
          end
          pdf.SetDrawColor(0, 0, 0)
        end
        
        pdf.Line(15, top, subject_width+g_width, top)
        pdf.Output
      end
    end
  end
end
