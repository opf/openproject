# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

module Redmine
  module Helpers
    # Simple class to handle gantt chart data
    class Gantt
      include ERB::Util
      include Redmine::I18n

      # :nodoc:
      # Some utility methods for the PDF export
      class PDF
        MaxCharactorsForSubject = 45
        TotalWidth = 280
        LeftPaneWidth = 100

        def self.right_pane_width
          TotalWidth - LeftPaneWidth
        end
      end

      attr_reader :year_from, :month_from, :date_from, :date_to, :zoom, :months, :truncated, :max_rows
      attr_accessor :query
      attr_accessor :project
      attr_accessor :view
      
      def initialize(options={})
        options = options.dup
        
        if options[:year] && options[:year].to_i >0
          @year_from = options[:year].to_i
          if options[:month] && options[:month].to_i >=1 && options[:month].to_i <= 12
            @month_from = options[:month].to_i
          else
            @month_from = 1
          end
        else
          @month_from ||= Date.today.month
          @year_from ||= Date.today.year
        end
        
        zoom = (options[:zoom] || User.current.pref[:gantt_zoom]).to_i
        @zoom = (zoom > 0 && zoom < 5) ? zoom : 2    
        months = (options[:months] || User.current.pref[:gantt_months]).to_i
        @months = (months > 0 && months < 25) ? months : 6
        
        # Save gantt parameters as user preference (zoom and months count)
        if (User.current.logged? && (@zoom != User.current.pref[:gantt_zoom] || @months != User.current.pref[:gantt_months]))
          User.current.pref[:gantt_zoom], User.current.pref[:gantt_months] = @zoom, @months
          User.current.preference.save
        end
        
        @date_from = Date.civil(@year_from, @month_from, 1)
        @date_to = (@date_from >> @months) - 1
        
        @subjects = ''
        @lines = ''
        @number_of_rows = nil
        
        @truncated = false
        if options.has_key?(:max_rows)
          @max_rows = options[:max_rows]
        else
          @max_rows = Setting.gantt_items_limit.blank? ? nil : Setting.gantt_items_limit.to_i
        end
      end

      def common_params
        { :controller => 'gantts', :action => 'show', :project_id => @project }
      end
      
      def params
        common_params.merge({  :zoom => zoom, :year => year_from, :month => month_from, :months => months })
      end
      
      def params_previous
        common_params.merge({:year => (date_from << months).year, :month => (date_from << months).month, :zoom => zoom, :months => months })
      end
      
      def params_next
        common_params.merge({:year => (date_from >> months).year, :month => (date_from >> months).month, :zoom => zoom, :months => months })
      end

            ### Extracted from the HTML view/helpers
      # Returns the number of rows that will be rendered on the Gantt chart
      def number_of_rows
        return @number_of_rows if @number_of_rows
        
        rows = if @project
          number_of_rows_on_project(@project)
        else
          Project.roots.visible.has_module('issue_tracking').inject(0) do |total, project|
            total += number_of_rows_on_project(project)
          end
        end
        
        rows > @max_rows ? @max_rows : rows
      end

      # Returns the number of rows that will be used to list a project on
      # the Gantt chart.  This will recurse for each subproject.
      def number_of_rows_on_project(project)
        # Remove the project requirement for Versions because it will
        # restrict issues to only be on the current project.  This
        # ends up missing issues which are assigned to shared versions.
        @query.project = nil if @query.project

        # One Root project
        count = 1
        # Issues without a Version
        count += project.issues.for_gantt.without_version.with_query(@query).count

        # Versions
        count += project.versions.count

        # Issues on the Versions
        project.versions.each do |version|
          count += version.fixed_issues.for_gantt.with_query(@query).count
        end

        # Subprojects
        project.children.visible.has_module('issue_tracking').each do |subproject|
          count += number_of_rows_on_project(subproject)
        end

        count
      end

      # Renders the subjects of the Gantt chart, the left side.
      def subjects(options={})
        render(options.merge(:only => :subjects)) unless @subjects_rendered
        @subjects
      end

      # Renders the lines of the Gantt chart, the right side
      def lines(options={})
        render(options.merge(:only => :lines)) unless @lines_rendered
        @lines
      end
      
      def render(options={})
        options = {:indent => 4, :render => :subject, :format => :html}.merge(options)
        
        @subjects = '' unless options[:only] == :lines
        @lines = '' unless options[:only] == :subjects
        @number_of_rows = 0
        
        if @project
          render_project(@project, options)
        else
          Project.roots.visible.has_module('issue_tracking').each do |project|
            render_project(project, options)
            break if abort?
          end
        end
        
        @subjects_rendered = true unless options[:only] == :lines
        @lines_rendered = true unless options[:only] == :subjects
        
        render_end(options)
      end

      def render_project(project, options={})
        options[:top] = 0 unless options.key? :top
        options[:indent_increment] = 20 unless options.key? :indent_increment
        options[:top_increment] = 20 unless options.key? :top_increment

        subject_for_project(project, options) unless options[:only] == :lines
        line_for_project(project, options) unless options[:only] == :subjects
        
        options[:top] += options[:top_increment]
        options[:indent] += options[:indent_increment]
        @number_of_rows += 1
        return if abort?
        
        # Second, Issues without a version
        issues = project.issues.for_gantt.without_version.with_query(@query).all(:limit => current_limit)
        sort_issues!(issues)
        if issues
          render_issues(issues, options)
          return if abort?
        end

        # Third, Versions
        project.versions.sort.each do |version|
          render_version(version, options)
          return if abort?
        end

        # Fourth, subprojects
        project.children.visible.has_module('issue_tracking').each do |project|
          render_project(project, options)
          return if abort?
        end unless project.leaf?

        # Remove indent to hit the next sibling
        options[:indent] -= options[:indent_increment]
      end

      def render_issues(issues, options={})
        issues.each do |i|
          subject_for_issue(i, options) unless options[:only] == :lines
          line_for_issue(i, options) unless options[:only] == :subjects
          
          options[:top] += options[:top_increment]
          @number_of_rows += 1
          return if abort?
        end
      end

      def render_version(version, options={})
        # Version header
        subject_for_version(version, options) unless options[:only] == :lines
        line_for_version(version, options) unless options[:only] == :subjects
        
        options[:top] += options[:top_increment]
        @number_of_rows += 1
        return if abort?
        
        # Remove the project requirement for Versions because it will
        # restrict issues to only be on the current project.  This
        # ends up missing issues which are assigned to shared versions.
        @query.project = nil if @query.project
        
        issues = version.fixed_issues.for_gantt.with_query(@query).all(:limit => current_limit)
        if issues
          sort_issues!(issues)
          # Indent issues
          options[:indent] += options[:indent_increment]
          render_issues(issues, options)
          options[:indent] -= options[:indent_increment]
        end
      end
      
      def render_end(options={})
        case options[:format]
        when :pdf        
          options[:pdf].Line(15, options[:top], PDF::TotalWidth, options[:top])
        end
      end

      def subject_for_project(project, options)
        case options[:format]
        when :html
          output = ''

          output << "<div class='project-name' style='position: absolute;line-height:1.2em;height:16px;top:#{options[:top]}px;left:#{options[:indent]}px;overflow:hidden;'><small>    "
          if project.is_a? Project
            output << "<span class='icon icon-projects #{project.overdue? ? 'project-overdue' : ''}'>"
            output << view.link_to_project(project)
            output << '</span>'
          else
            ActiveRecord::Base.logger.debug "Gantt#subject_for_project was not given a project"
            ''
          end
          output << "</small></div>"
          @subjects << output
          output
        when :image
          
          options[:image].fill('black')
          options[:image].stroke('transparent')
          options[:image].stroke_width(1)
          options[:image].text(options[:indent], options[:top] + 2, project.name)
        when :pdf
          pdf_new_page?(options)
          options[:pdf].SetY(options[:top])
          options[:pdf].SetX(15)
          
          char_limit = PDF::MaxCharactorsForSubject - options[:indent]
          options[:pdf].Cell(options[:subject_width]-15, 5, (" " * options[:indent]) +"#{project.name}".sub(/^(.{#{char_limit}}[^\s]*\s).*$/, '\1 (...)'), "LR")
        
          options[:pdf].SetY(options[:top])
          options[:pdf].SetX(options[:subject_width])
          options[:pdf].Cell(options[:g_width], 5, "", "LR")
        end
      end

      def line_for_project(project, options)
        # Skip versions that don't have a start_date or due date
        if project.is_a?(Project) && project.start_date && project.due_date
          options[:zoom] ||= 1
          options[:g_width] ||= (self.date_to - self.date_from + 1) * options[:zoom]

          
          case options[:format]
          when :html
            coords = coordinates(project.start_date, project.due_date, project.completed_percent(:include_subprojects => true), options[:zoom])
            label = "#{h project } #{h project.completed_percent(:include_subprojects => true).to_i.to_s}%"
            output = html_task(options, coords, :css => "project task", :label => label, :markers => true)
            
            @lines << output
            output
          when :image
            coords = coordinates(project.start_date, project.due_date, project.completed_percent(:include_subprojects => true), options[:zoom])
            label = "#{h project } #{h project.completed_percent(:include_subprojects => true).to_i.to_s}%"
            image_task(options, coords, :label => label, :markers => true, :height => 3)
          when :pdf
            coords = coordinates(project.start_date, project.due_date, project.completed_percent(:include_subprojects => true), options[:zoom])
            label = "#{h project } #{h project.completed_percent(:include_subprojects => true).to_i.to_s}%"
            pdf_task(options, coords, :label => label, :markers => true, :height => 0.8)
          end
        else
          ActiveRecord::Base.logger.debug "Gantt#line_for_project was not given a project with a start_date"
          ''
        end
      end

      def subject_for_version(version, options)
        case options[:format]
        when :html
          output = ''
          output << "<div class='version-name' style='position: absolute;line-height:1.2em;height:16px;top:#{options[:top]}px;left:#{options[:indent]}px;overflow:hidden;'><small>    "
          if version.is_a? Version
            output << "<span class='icon icon-package #{version.behind_schedule? ? 'version-behind-schedule' : ''} #{version.overdue? ? 'version-overdue' : ''}'>"
            output << view.link_to_version(version)
            output << '</span>'
          else
            ActiveRecord::Base.logger.debug "Gantt#subject_for_version was not given a version"
            ''
          end
          output << "</small></div>"
          @subjects << output
          output
        when :image
          options[:image].fill('black')
          options[:image].stroke('transparent')
          options[:image].stroke_width(1)
          options[:image].text(options[:indent], options[:top] + 2, version.to_s_with_project)
        when :pdf
          pdf_new_page?(options)
          options[:pdf].SetY(options[:top])
          options[:pdf].SetX(15)
          
          char_limit = PDF::MaxCharactorsForSubject - options[:indent]
          options[:pdf].Cell(options[:subject_width]-15, 5, (" " * options[:indent]) +"#{version.to_s_with_project}".sub(/^(.{#{char_limit}}[^\s]*\s).*$/, '\1 (...)'), "LR")
        
          options[:pdf].SetY(options[:top])
          options[:pdf].SetX(options[:subject_width])
          options[:pdf].Cell(options[:g_width], 5, "", "LR")
        end
      end

      def line_for_version(version, options)
        # Skip versions that don't have a start_date
        if version.is_a?(Version) && version.start_date && version.due_date
          options[:zoom] ||= 1
          options[:g_width] ||= (self.date_to - self.date_from + 1) * options[:zoom]

          case options[:format]
          when :html
            coords = coordinates(version.fixed_issues.minimum('start_date'), version.due_date, version.completed_pourcent, options[:zoom])
            label = "#{h version } #{h version.completed_pourcent.to_i.to_s}%"
            label = h("#{version.project} -") + label unless @project && @project == version.project
            output = html_task(options, coords, :css => "version task", :label => label, :markers => true)
            
            @lines << output
            output
          when :image
            coords = coordinates(version.fixed_issues.minimum('start_date'), version.due_date, version.completed_pourcent, options[:zoom])
            label = "#{h version } #{h version.completed_pourcent.to_i.to_s}%"
            label = h("#{version.project} -") + label unless @project && @project == version.project
            image_task(options, coords, :label => label, :markers => true, :height => 3)
          when :pdf
            coords = coordinates(version.fixed_issues.minimum('start_date'), version.due_date, version.completed_pourcent, options[:zoom])
            label = "#{h version } #{h version.completed_pourcent.to_i.to_s}%"
            label = h("#{version.project} -") + label unless @project && @project == version.project
            pdf_task(options, coords, :label => label, :markers => true, :height => 0.8)
          end
        else
          ActiveRecord::Base.logger.debug "Gantt#line_for_version was not given a version with a start_date"
          ''
        end
      end

      def subject_for_issue(issue, options)
        case options[:format]
        when :html
          output = ''
          output << "<div class='tooltip'>"
          output << "<div class='issue-subject' style='position: absolute;line-height:1.2em;height:16px;top:#{options[:top]}px;left:#{options[:indent]}px;overflow:hidden;'><small>    "
          if issue.is_a? Issue
            css_classes = []
            css_classes << 'issue-overdue' if issue.overdue?
            css_classes << 'issue-behind-schedule' if issue.behind_schedule?
            css_classes << 'icon icon-issue' unless Setting.gravatar_enabled? && issue.assigned_to

            if issue.assigned_to.present?
              assigned_string = l(:field_assigned_to) + ": " + issue.assigned_to.name
              output << view.avatar(issue.assigned_to, :class => 'gravatar icon-gravatar', :size => 10, :title => assigned_string)
            end
            output << "<span class='#{css_classes.join(' ')}'>"
            output << view.link_to_issue(issue)
            output << '</span>'
          else
            ActiveRecord::Base.logger.debug "Gantt#subject_for_issue was not given an issue"
            ''
          end
          output << "</small></div>"

          # Tooltip
          if issue.is_a? Issue
            output << "<span class='tip' style='position: absolute;top:#{ options[:top].to_i + 16 }px;left:#{ options[:indent].to_i + 20 }px;'>"
            output << view.render_issue_tooltip(issue)
            output << "</span>"
          end

          output << "</div>"
          @subjects << output
          output
        when :image
          options[:image].fill('black')
          options[:image].stroke('transparent')
          options[:image].stroke_width(1)
          options[:image].text(options[:indent], options[:top] + 2, issue.subject)
        when :pdf
          pdf_new_page?(options)
          options[:pdf].SetY(options[:top])
          options[:pdf].SetX(15)
          
          char_limit = PDF::MaxCharactorsForSubject - options[:indent]
          options[:pdf].Cell(options[:subject_width]-15, 5, (" " * options[:indent]) +"#{issue.tracker} #{issue.id}: #{issue.subject}".sub(/^(.{#{char_limit}}[^\s]*\s).*$/, '\1 (...)'), "LR")
        
          options[:pdf].SetY(options[:top])
          options[:pdf].SetX(options[:subject_width])
          options[:pdf].Cell(options[:g_width], 5, "", "LR")
        end
      end

      def line_for_issue(issue, options)
        # Skip issues that don't have a due_before (due_date or version's due_date)
        if issue.is_a?(Issue) && issue.due_before
          case options[:format]
          when :html
            coords = coordinates(issue.start_date, issue.due_before, issue.done_ratio, options[:zoom])
            css = "task " + (issue.leaf? ? 'leaf' : 'parent')
            output = html_task(options, coords, :css => css, :label => "#{ issue.status.name } #{ issue.done_ratio }%", :issue => issue)
            
            @lines << output
            output
          
          when :image
            coords = coordinates(issue.start_date, issue.due_before, issue.done_ratio, options[:zoom])
            image_task(options, coords, :label => "#{ issue.status.name } #{ issue.done_ratio }%")

          when :pdf
            coords = coordinates(issue.start_date, issue.due_before, issue.done_ratio, options[:zoom])
            pdf_task(options, coords, :label => "#{ issue.status.name } #{ issue.done_ratio }%")
        end
        else
          ActiveRecord::Base.logger.debug "GanttHelper#line_for_issue was not given an issue with a due_before"
          ''
        end
      end

      # Generates a gantt image
      # Only defined if RMagick is avalaible
      def to_image(format='PNG')
        date_to = (@date_from >> @months)-1    
        show_weeks = @zoom > 1
        show_days = @zoom > 2
        
        subject_width = 400
        header_heigth = 18
        # width of one day in pixels
        zoom = @zoom*2
        g_width = (@date_to - @date_from + 1)*zoom
        g_height = 20 * number_of_rows + 30
        headers_heigth = (show_weeks ? 2*header_heigth : header_heigth)
        height = g_height + headers_heigth
            
        imgl = Magick::ImageList.new
        imgl.new_image(subject_width+g_width+1, height)
        gc = Magick::Draw.new
        
        # Subjects
        gc.stroke('transparent')
        subjects(:image => gc, :top => (headers_heigth + 20), :indent => 4, :format => :image)
    
        # Months headers
        month_f = @date_from
        left = subject_width
        @months.times do 
          width = ((month_f >> 1) - month_f) * zoom
          gc.fill('white')
          gc.stroke('grey')
          gc.stroke_width(1)
          gc.rectangle(left, 0, left + width, height)
          gc.fill('black')
          gc.stroke('transparent')
          gc.stroke_width(1)
          gc.text(left.round + 8, 14, "#{month_f.year}-#{month_f.month}")
          left = left + width
          month_f = month_f >> 1
        end
        
        # Weeks headers
        if show_weeks
        	left = subject_width
        	height = header_heigth
        	if @date_from.cwday == 1
        	    # date_from is monday
                week_f = date_from
        	else
        	    # find next monday after date_from
        		week_f = @date_from + (7 - @date_from.cwday + 1)
        		width = (7 - @date_from.cwday + 1) * zoom
                gc.fill('white')
                gc.stroke('grey')
                gc.stroke_width(1)
                gc.rectangle(left, header_heigth, left + width, 2*header_heigth + g_height-1)
        		left = left + width
        	end
        	while week_f <= date_to
        		width = (week_f + 6 <= date_to) ? 7 * zoom : (date_to - week_f + 1) * zoom
                gc.fill('white')
                gc.stroke('grey')
                gc.stroke_width(1)
                gc.rectangle(left.round, header_heigth, left.round + width, 2*header_heigth + g_height-1)
                gc.fill('black')
                gc.stroke('transparent')
                gc.stroke_width(1)
                gc.text(left.round + 2, header_heigth + 14, week_f.cweek.to_s)
        		left = left + width
        		week_f = week_f+7
        	end
        end
        
        # Days details (week-end in grey)
        if show_days
        	left = subject_width
        	height = g_height + header_heigth - 1
        	wday = @date_from.cwday
        	(date_to - @date_from + 1).to_i.times do 
              width =  zoom
              gc.fill(wday == 6 || wday == 7 ? '#eee' : 'white')
              gc.stroke('grey')
              gc.stroke_width(1)
              gc.rectangle(left, 2*header_heigth, left + width, 2*header_heigth + g_height-1)
              left = left + width
              wday = wday + 1
              wday = 1 if wday > 7
        	end
        end
    
        # border
        gc.fill('transparent')
        gc.stroke('grey')
        gc.stroke_width(1)
        gc.rectangle(0, 0, subject_width+g_width, headers_heigth)
        gc.stroke('black')
        gc.rectangle(0, 0, subject_width+g_width, g_height+ headers_heigth-1)
            
        # content
        top = headers_heigth + 20

        gc.stroke('transparent')
        lines(:image => gc, :top => top, :zoom => zoom, :subject_width => subject_width, :format => :image)
        
        # today red line
        if Date.today >= @date_from and Date.today <= date_to
          gc.stroke('red')
          x = (Date.today-@date_from+1)*zoom + subject_width
          gc.line(x, headers_heigth, x, headers_heigth + g_height-1)      
        end    
        
        gc.draw(imgl)
        imgl.format = format
        imgl.to_blob
      end if Object.const_defined?(:Magick)

      def to_pdf
        pdf = ::Redmine::Export::PDF::IFPDF.new(current_language)
        pdf.SetTitle("#{l(:label_gantt)} #{project}")
        pdf.AliasNbPages
        pdf.footer_date = format_date(Date.today)
        pdf.AddPage("L")
        pdf.SetFontStyle('B',12)
        pdf.SetX(15)
        pdf.Cell(PDF::LeftPaneWidth, 20, project.to_s)
        pdf.Ln
        pdf.SetFontStyle('B',9)
        
        subject_width = PDF::LeftPaneWidth
        header_heigth = 5
        
        headers_heigth = header_heigth
        show_weeks = false
        show_days = false
        
        if self.months < 7
          show_weeks = true
          headers_heigth = 2*header_heigth
          if self.months < 3
            show_days = true
            headers_heigth = 3*header_heigth
          end
        end
        
        g_width = PDF.right_pane_width
        zoom = (g_width) / (self.date_to - self.date_from + 1)
        g_height = 120
        t_height = g_height + headers_heigth
        
        y_start = pdf.GetY
        
        # Months headers
        month_f = self.date_from
        left = subject_width
        height = header_heigth
        self.months.times do 
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
          if self.date_from.cwday == 1
            # self.date_from is monday
            week_f = self.date_from
          else
            # find next monday after self.date_from
            week_f = self.date_from + (7 - self.date_from.cwday + 1)
            width = (7 - self.date_from.cwday + 1) * zoom-1
            pdf.SetY(y_start + header_heigth)
            pdf.SetX(left)
            pdf.Cell(width + 1, height, "", "LTR")
            left = left + width+1
          end
          while week_f <= self.date_to
            width = (week_f + 6 <= self.date_to) ? 7 * zoom : (self.date_to - week_f + 1) * zoom
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
          wday = self.date_from.cwday
          pdf.SetFontStyle('B',7)
          (self.date_to - self.date_from + 1).to_i.times do 
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
        options = {
          :top => top,
          :zoom => zoom,
          :subject_width => subject_width,
          :g_width => g_width,
          :indent => 0,
          :indent_increment => 5,
          :top_increment => 5,
          :format => :pdf,
          :pdf => pdf
        }
        render(options)
        pdf.Output
      end
      
      private
      
      def coordinates(start_date, end_date, progress, zoom=nil)
        zoom ||= @zoom
        
        coords = {}
        if start_date && end_date && start_date < self.date_to && end_date > self.date_from
          if start_date > self.date_from
            coords[:start] = start_date - self.date_from
            coords[:bar_start] = start_date - self.date_from
          else
            coords[:bar_start] = 0
          end
          if end_date < self.date_to
            coords[:end] = end_date - self.date_from
            coords[:bar_end] = end_date - self.date_from + 1
          else
            coords[:bar_end] = self.date_to - self.date_from + 1
          end
        
          if progress
            progress_date = start_date + (end_date - start_date) * (progress / 100.0)
            if progress_date > self.date_from && progress_date > start_date
              if progress_date < self.date_to
                coords[:bar_progress_end] = progress_date - self.date_from + 1
              else
                coords[:bar_progress_end] = self.date_to - self.date_from + 1
              end
            end
            
            if progress_date < Date.today
              late_date = [Date.today, end_date].min
              if late_date > self.date_from && late_date > start_date
                if late_date < self.date_to
                  coords[:bar_late_end] = late_date - self.date_from + 1
                else
                  coords[:bar_late_end] = self.date_to - self.date_from + 1
                end
              end
            end
          end
        end
        
        # Transforms dates into pixels witdh
        coords.keys.each do |key|
          coords[key] = (coords[key] * zoom).floor
        end
        coords
      end

      # Sorts a collection of issues by start_date, due_date, id for gantt rendering
      def sort_issues!(issues)
        issues.sort! do |a, b|
          cmp = 0
          cmp = (a.start_date <=> b.start_date) if a.start_date? && b.start_date?
          cmp = (a.due_date <=> b.due_date) if cmp == 0 && a.due_date? && b.due_date?
          cmp = (a.id <=> b.id) if cmp == 0
          cmp
        end
      end
      
      def current_limit
        if @max_rows
          @max_rows - @number_of_rows
        else
          nil
        end
      end
      
      def abort?
        if @max_rows && @number_of_rows >= @max_rows
          @truncated = true
        end
      end
      
      def pdf_new_page?(options)
        if options[:top] > 180
          options[:pdf].Line(15, options[:top], PDF::TotalWidth, options[:top])
          options[:pdf].AddPage("L")
          options[:top] = 15
          options[:pdf].Line(15, options[:top] - 0.1, PDF::TotalWidth, options[:top] - 0.1)
        end
      end
      
      def html_task(params, coords, options={})
        output = ''
        # Renders the task bar, with progress and late
        if coords[:bar_start] && coords[:bar_end]
          output << "<div style='top:#{ params[:top] }px;left:#{ coords[:bar_start] }px;width:#{ coords[:bar_end] - coords[:bar_start] - 2}px;' class='#{options[:css]} task_todo'>&nbsp;</div>"
          
          if coords[:bar_late_end]
            output << "<div style='top:#{ params[:top] }px;left:#{ coords[:bar_start] }px;width:#{ coords[:bar_late_end] - coords[:bar_start] - 2}px;' class='#{options[:css]} task_late'>&nbsp;</div>"
          end
          if coords[:bar_progress_end]
            output << "<div style='top:#{ params[:top] }px;left:#{ coords[:bar_start] }px;width:#{ coords[:bar_progress_end] - coords[:bar_start] - 2}px;' class='#{options[:css]} task_done'>&nbsp;</div>"
          end
        end
        # Renders the markers
        if options[:markers]
          if coords[:start]
            output << "<div style='top:#{ params[:top] }px;left:#{ coords[:start] }px;width:15px;' class='#{options[:css]} marker starting'>&nbsp;</div>"
          end
          if coords[:end]
            output << "<div style='top:#{ params[:top] }px;left:#{ coords[:end] }px;width:15px;' class='#{options[:css]} marker ending'>&nbsp;</div>"
          end
        end
        # Renders the label on the right
        if options[:label]
          output << "<div style='top:#{ params[:top] }px;left:#{ (coords[:bar_end] || 0) + 5 }px;' class='#{options[:css]} label'>"
          output << options[:label]
          output << "</div>"
        end
        # Renders the tooltip
        if options[:issue] && coords[:bar_start] && coords[:bar_end]
          output << "<div class='tooltip' style='position: absolute;top:#{ params[:top] }px;left:#{ coords[:bar_start] }px;width:#{ coords[:bar_end] - coords[:bar_start] }px;height:12px;'>"
          output << '<span class="tip">'
          output << view.render_issue_tooltip(options[:issue])
          output << "</span></div>"
        end
        
        output
      end
      
      def pdf_task(params, coords, options={})
        height = options[:height] || 2
        
        # Renders the task bar, with progress and late
        if coords[:bar_start] && coords[:bar_end]
          params[:pdf].SetY(params[:top]+1.5)
          params[:pdf].SetX(params[:subject_width] + coords[:bar_start])
          params[:pdf].SetFillColor(200,200,200)
          params[:pdf].Cell(coords[:bar_end] - coords[:bar_start], height, "", 0, 0, "", 1)
            
          if coords[:bar_late_end]
            params[:pdf].SetY(params[:top]+1.5)
            params[:pdf].SetX(params[:subject_width] + coords[:bar_start])
            params[:pdf].SetFillColor(255,100,100)
            params[:pdf].Cell(coords[:bar_late_end] - coords[:bar_start], height, "", 0, 0, "", 1)
          end
          if coords[:bar_progress_end]
            params[:pdf].SetY(params[:top]+1.5)
            params[:pdf].SetX(params[:subject_width] + coords[:bar_start])
            params[:pdf].SetFillColor(90,200,90)
            params[:pdf].Cell(coords[:bar_progress_end] - coords[:bar_start], height, "", 0, 0, "", 1)
          end
        end
        # Renders the markers
        if options[:markers]
          if coords[:start]
            params[:pdf].SetY(params[:top] + 1)
            params[:pdf].SetX(params[:subject_width] + coords[:start] - 1)
            params[:pdf].SetFillColor(50,50,200)
            params[:pdf].Cell(2, 2, "", 0, 0, "", 1) 
          end
          if coords[:end]
            params[:pdf].SetY(params[:top] + 1)
            params[:pdf].SetX(params[:subject_width] + coords[:end] - 1)
            params[:pdf].SetFillColor(50,50,200)
            params[:pdf].Cell(2, 2, "", 0, 0, "", 1) 
          end
        end
        # Renders the label on the right
        if options[:label]
          params[:pdf].SetX(params[:subject_width] + (coords[:bar_end] || 0) + 5)
          params[:pdf].Cell(30, 2, options[:label])
        end
      end

      def image_task(params, coords, options={})
        height = options[:height] || 6
        
        # Renders the task bar, with progress and late
        if coords[:bar_start] && coords[:bar_end]
          params[:image].fill('grey')
          params[:image].rectangle(params[:subject_width] + coords[:bar_start], params[:top], params[:subject_width] + coords[:bar_end], params[:top] - height)
 
          if coords[:bar_late_end]
            params[:image].fill('red')
            params[:image].rectangle(params[:subject_width] + coords[:bar_start], params[:top], params[:subject_width] + coords[:bar_late_end], params[:top] - height)
          end
          if coords[:bar_progress_end]
            params[:image].fill('green')
            params[:image].rectangle(params[:subject_width] + coords[:bar_start], params[:top], params[:subject_width] + coords[:bar_progress_end], params[:top] - height)
          end
        end
        # Renders the markers
        if options[:markers]
          if coords[:start]
            params[:image].fill('blue')
            params[:image].rectangle(params[:subject_width] + coords[:start], params[:top] + 1, params[:subject_width] + coords[:start] + 4, params[:top] - 4)
          end
          if coords[:end]
            params[:image].fill('blue')
            params[:image].rectangle(params[:subject_width] + coords[:end], params[:top] + 1, params[:subject_width] + coords[:end] + 4, params[:top] - 4)
          end
        end
        # Renders the label on the right
        if options[:label]
          params[:image].fill('black')
          params[:image].text(params[:subject_width] + (coords[:bar_end] || 0) + 5,params[:top] + 1, options[:label])
        end
      end
    end
  end
end
