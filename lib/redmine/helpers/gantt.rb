# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
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
        
        @issue_ancestors = []
        
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

      # Returns the number of rows that will be rendered on the Gantt chart
      def number_of_rows
        return @number_of_rows if @number_of_rows
        
        rows = projects.inject(0) {|total, p| total += number_of_rows_on_project(p)}

        if @max_rows.present?
          rows > @max_rows ? @max_rows : rows
        else
          rows
        end
      end

      # Returns the number of rows that will be used to list a project on
      # the Gantt chart.  This will recurse for each subproject.
      def number_of_rows_on_project(project)
        return 0 unless projects.include?(project)
        count = 1
        count += project_issues(project).size
        count += project_versions(project).size
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
      
      # Returns issues that will be rendered
      def issues
        @issues ||= @query.issues(
          :include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
          :order => "#{Project.table_name}.lft ASC, #{Issue.table_name}.id ASC", 
          :limit => @max_rows
        )
      end
      
      # Return all the project nodes that will be displayed
      def projects
        return @projects if @projects
        
        ids = issues.collect(&:project).uniq.collect(&:id)
        if ids.any?
          # All issues projects and their visible ancestors
          @projects = Project.visible.all(
            :joins => "LEFT JOIN #{Project.table_name} child ON #{Project.table_name}.lft <= child.lft AND #{Project.table_name}.rgt >= child.rgt",
            :conditions => ["child.id IN (?)", ids],
            :order => "#{Project.table_name}.lft ASC"
          ).uniq
        else
          @projects = []
        end
      end
      
      # Returns the issues that belong to +project+
      def project_issues(project)
        @issues_by_project ||= issues.group_by(&:project)
        @issues_by_project[project] || []
      end
      
      # Returns the distinct versions of the issues that belong to +project+
      def project_versions(project)
        project_issues(project).collect(&:fixed_version).compact.uniq
      end
      
      # Returns the issues that belong to +project+ and are assigned to +version+
      def version_issues(project, version)
        project_issues(project).select {|issue| issue.fixed_version == version}
      end
      
      def render(options={})
        options = {:top => 0, :top_increment => 20, :indent_increment => 20, :render => :subject, :format => :html}.merge(options)
        indent = options[:indent] || 4
        
        @subjects = '' unless options[:only] == :lines
        @lines = '' unless options[:only] == :subjects
        @number_of_rows = 0
        
        Project.project_tree(projects) do |project, level|
          options[:indent] = indent + level * options[:indent_increment]
          render_project(project, options)
          break if abort?
        end
        
        @subjects_rendered = true unless options[:only] == :lines
        @lines_rendered = true unless options[:only] == :subjects
        
        render_end(options)
      end

      def render_project(project, options={})
        subject_for_project(project, options) unless options[:only] == :lines
        line_for_project(project, options) unless options[:only] == :subjects
        
        options[:top] += options[:top_increment]
        options[:indent] += options[:indent_increment]
        @number_of_rows += 1
        return if abort?
        
        issues = project_issues(project).select {|i| i.fixed_version.nil?}
        sort_issues!(issues)
        if issues
          render_issues(issues, options)
          return if abort?
        end
        
        versions = project_versions(project)
        versions.each do |version|
          render_version(project, version, options)
        end

        # Remove indent to hit the next sibling
        options[:indent] -= options[:indent_increment]
      end

      def render_issues(issues, options={})
        @issue_ancestors = []
        
        issues.each do |i|
          subject_for_issue(i, options) unless options[:only] == :lines
          line_for_issue(i, options) unless options[:only] == :subjects
          
          options[:top] += options[:top_increment]
          @number_of_rows += 1
          break if abort?
        end
        
        options[:indent] -= (options[:indent_increment] * @issue_ancestors.size)
      end

      def render_version(project, version, options={})
        # Version header
        subject_for_version(version, options) unless options[:only] == :lines
        line_for_version(version, options) unless options[:only] == :subjects
        
        options[:top] += options[:top_increment]
        @number_of_rows += 1
        return if abort?
        
        issues = version_issues(project, version)
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
          subject = "<span class='icon icon-projects #{project.overdue? ? 'project-overdue' : ''}'>"
          subject << view.link_to_project(project)
          subject << '</span>'
          html_subject(options, subject, :css => "project-name")
        when :image
          image_subject(options, project.name)
        when :pdf
          pdf_new_page?(options)
          pdf_subject(options, project.name)
        end
      end

      def line_for_project(project, options)
        # Skip versions that don't have a start_date or due date
        if project.is_a?(Project) && project.start_date && project.due_date
          options[:zoom] ||= 1
          options[:g_width] ||= (self.date_to - self.date_from + 1) * options[:zoom]
            
          coords = coordinates(project.start_date, project.due_date, nil, options[:zoom])
          label = h(project)
          
          case options[:format]
          when :html
            html_task(options, coords, :css => "project task", :label => label, :markers => true)
          when :image
            image_task(options, coords, :label => label, :markers => true, :height => 3)
          when :pdf
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
          subject = "<span class='icon icon-package #{version.behind_schedule? ? 'version-behind-schedule' : ''} #{version.overdue? ? 'version-overdue' : ''}'>"
          subject << view.link_to_version(version)
          subject << '</span>'
          html_subject(options, subject, :css => "version-name")
        when :image
          image_subject(options, version.to_s_with_project)
        when :pdf
          pdf_new_page?(options)
          pdf_subject(options, version.to_s_with_project)
        end
      end

      def line_for_version(version, options)
        # Skip versions that don't have a start_date
        if version.is_a?(Version) && version.start_date && version.due_date
          options[:zoom] ||= 1
          options[:g_width] ||= (self.date_to - self.date_from + 1) * options[:zoom]
          
          coords = coordinates(version.start_date, version.due_date, version.completed_pourcent, options[:zoom])
          label = "#{h version } #{h version.completed_pourcent.to_i.to_s}%"
          label = h("#{version.project} -") + label unless @project && @project == version.project

          case options[:format]
          when :html
            html_task(options, coords, :css => "version task", :label => label, :markers => true)
          when :image
            image_task(options, coords, :label => label, :markers => true, :height => 3)
          when :pdf
            pdf_task(options, coords, :label => label, :markers => true, :height => 0.8)
          end
        else
          ActiveRecord::Base.logger.debug "Gantt#line_for_version was not given a version with a start_date"
          ''
        end
      end

      def subject_for_issue(issue, options)
        while @issue_ancestors.any? && !issue.is_descendant_of?(@issue_ancestors.last)
          @issue_ancestors.pop
          options[:indent] -= options[:indent_increment]
        end
          
        output = case options[:format]
        when :html
          css_classes = ''
          css_classes << ' issue-overdue' if issue.overdue?
          css_classes << ' issue-behind-schedule' if issue.behind_schedule?
          css_classes << ' icon icon-issue' unless Setting.gravatar_enabled? && issue.assigned_to
          
          subject = "<span class='#{css_classes}'>"
          if issue.assigned_to.present?
            assigned_string = l(:field_assigned_to) + ": " + issue.assigned_to.name
            subject << view.avatar(issue.assigned_to, :class => 'gravatar icon-gravatar', :size => 10, :title => assigned_string).to_s
          end
          subject << view.link_to_issue(issue)
          subject << '</span>'
          html_subject(options, subject, :css => "issue-subject", :title => issue.subject) + "\n"
        when :image
          image_subject(options, issue.subject)
        when :pdf
          pdf_new_page?(options)
          pdf_subject(options, issue.subject)
        end

        unless issue.leaf?
          @issue_ancestors << issue
          options[:indent] += options[:indent_increment]
        end
        
        output
      end

      def line_for_issue(issue, options)
        # Skip issues that don't have a due_before (due_date or version's due_date)
        if issue.is_a?(Issue) && issue.due_before
          coords = coordinates(issue.start_date, issue.due_before, issue.done_ratio, options[:zoom])
          label = "#{ issue.status.name } #{ issue.done_ratio }%"
          
          case options[:format]
          when :html
            html_task(options, coords, :css => "task " + (issue.leaf? ? 'leaf' : 'parent'), :label => label, :issue => issue, :markers => !issue.leaf?)
          when :image
            image_task(options, coords, :label => label)
          when :pdf
            pdf_task(options, coords, :label => label)
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
              gc.stroke('#ddd')
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
        pdf.alias_nb_pages
        pdf.footer_date = format_date(Date.today)
        pdf.AddPage("L")
        pdf.SetFontStyle('B',12)
        pdf.SetX(15)
        pdf.RDMCell(PDF::LeftPaneWidth, 20, project.to_s)
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
          pdf.RDMCell(width, height, "#{month_f.year}-#{month_f.month}", "LTR", 0, "C")
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
            pdf.RDMCell(width + 1, height, "", "LTR")
            left = left + width+1
          end
          while week_f <= self.date_to
            width = (week_f + 6 <= self.date_to) ? 7 * zoom : (self.date_to - week_f + 1) * zoom
            pdf.SetY(y_start + header_heigth)
            pdf.SetX(left)
            pdf.RDMCell(width, height, (width >= 5 ? week_f.cweek.to_s : ""), "LTR", 0, "C")
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
            pdf.RDMCell(width, height, day_name(wday).first, "LTR", 0, "C")
            left = left + width
            wday = wday + 1
            wday = 1 if wday > 7
          end
        end
        
        pdf.SetY(y_start)
        pdf.SetX(15)
        pdf.RDMCell(subject_width+g_width-15, headers_heigth, "", 1)
        
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
            progress_date = start_date + (end_date - start_date + 1) * (progress / 100.0)
            if progress_date > self.date_from && progress_date > start_date
              if progress_date < self.date_to
                coords[:bar_progress_end] = progress_date - self.date_from
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
        issues.sort! { |a, b| gantt_issue_compare(a, b, issues) }
      end
  
      # TODO: top level issues should be sorted by start date
      def gantt_issue_compare(x, y, issues)
        if x.root_id == y.root_id
          x.lft <=> y.lft
        else
          x.root_id <=> y.root_id
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
      
      def html_subject(params, subject, options={})
        style = "position: absolute;top:#{params[:top]}px;left:#{params[:indent]}px;"
        style << "width:#{params[:subject_width] - params[:indent]}px;" if params[:subject_width]
        
        output = view.content_tag 'div', subject, :class => options[:css], :style => style, :title => options[:title]
        @subjects << output
        output
      end
      
      def pdf_subject(params, subject, options={})
        params[:pdf].SetY(params[:top])
        params[:pdf].SetX(15)
        
        char_limit = PDF::MaxCharactorsForSubject - params[:indent]
        params[:pdf].RDMCell(params[:subject_width]-15, 5, (" " * params[:indent]) +  subject.to_s.sub(/^(.{#{char_limit}}[^\s]*\s).*$/, '\1 (...)'), "LR")
      
        params[:pdf].SetY(params[:top])
        params[:pdf].SetX(params[:subject_width])
        params[:pdf].RDMCell(params[:g_width], 5, "", "LR")
      end
      
      def image_subject(params, subject, options={})
        params[:image].fill('black')
        params[:image].stroke('transparent')
        params[:image].stroke_width(1)
        params[:image].text(params[:indent], params[:top] + 2, subject)
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
            output << "<div style='top:#{ params[:top] }px;left:#{ coords[:end] + params[:zoom] }px;width:15px;' class='#{options[:css]} marker ending'>&nbsp;</div>"
          end
        end
        # Renders the label on the right
        if options[:label]
          output << "<div style='top:#{ params[:top] }px;left:#{ (coords[:bar_end] || 0) + 8 }px;' class='#{options[:css]} label'>"
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
        @lines << output
        output
      end
      
      def pdf_task(params, coords, options={})
        height = options[:height] || 2
        
        # Renders the task bar, with progress and late
        if coords[:bar_start] && coords[:bar_end]
          params[:pdf].SetY(params[:top]+1.5)
          params[:pdf].SetX(params[:subject_width] + coords[:bar_start])
          params[:pdf].SetFillColor(200,200,200)
          params[:pdf].RDMCell(coords[:bar_end] - coords[:bar_start], height, "", 0, 0, "", 1)
            
          if coords[:bar_late_end]
            params[:pdf].SetY(params[:top]+1.5)
            params[:pdf].SetX(params[:subject_width] + coords[:bar_start])
            params[:pdf].SetFillColor(255,100,100)
            params[:pdf].RDMCell(coords[:bar_late_end] - coords[:bar_start], height, "", 0, 0, "", 1)
          end
          if coords[:bar_progress_end]
            params[:pdf].SetY(params[:top]+1.5)
            params[:pdf].SetX(params[:subject_width] + coords[:bar_start])
            params[:pdf].SetFillColor(90,200,90)
            params[:pdf].RDMCell(coords[:bar_progress_end] - coords[:bar_start], height, "", 0, 0, "", 1)
          end
        end
        # Renders the markers
        if options[:markers]
          if coords[:start]
            params[:pdf].SetY(params[:top] + 1)
            params[:pdf].SetX(params[:subject_width] + coords[:start] - 1)
            params[:pdf].SetFillColor(50,50,200)
            params[:pdf].RDMCell(2, 2, "", 0, 0, "", 1) 
          end
          if coords[:end]
            params[:pdf].SetY(params[:top] + 1)
            params[:pdf].SetX(params[:subject_width] + coords[:end] - 1)
            params[:pdf].SetFillColor(50,50,200)
            params[:pdf].RDMCell(2, 2, "", 0, 0, "", 1) 
          end
        end
        # Renders the label on the right
        if options[:label]
          params[:pdf].SetX(params[:subject_width] + (coords[:bar_end] || 0) + 5)
          params[:pdf].RDMCell(30, 2, options[:label])
        end
      end

      def image_task(params, coords, options={})
        height = options[:height] || 6
        
        # Renders the task bar, with progress and late
        if coords[:bar_start] && coords[:bar_end]
          params[:image].fill('#aaa')
          params[:image].rectangle(params[:subject_width] + coords[:bar_start], params[:top], params[:subject_width] + coords[:bar_end], params[:top] - height)
 
          if coords[:bar_late_end]
            params[:image].fill('#f66')
            params[:image].rectangle(params[:subject_width] + coords[:bar_start], params[:top], params[:subject_width] + coords[:bar_late_end], params[:top] - height)
          end
          if coords[:bar_progress_end]
            params[:image].fill('#00c600')
            params[:image].rectangle(params[:subject_width] + coords[:bar_start], params[:top], params[:subject_width] + coords[:bar_progress_end], params[:top] - height)
          end
        end
        # Renders the markers
        if options[:markers]
          if coords[:start]
            x = params[:subject_width] + coords[:start]
            y = params[:top] - height / 2
            params[:image].fill('blue')
            params[:image].polygon(x-4, y, x, y-4, x+4, y, x, y+4)
          end
          if coords[:end]
            x = params[:subject_width] + coords[:end] + params[:zoom]
            y = params[:top] - height / 2
            params[:image].fill('blue')
            params[:image].polygon(x-4, y, x, y-4, x+4, y, x, y+4)
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
