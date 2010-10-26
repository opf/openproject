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

      attr_reader :year_from, :month_from, :date_from, :date_to, :zoom, :months
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
        if @project
          return number_of_rows_on_project(@project)
        else
          Project.roots.inject(0) do |total, project|
            total += number_of_rows_on_project(project)
          end
        end
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
        project.children.each do |subproject|
          count += number_of_rows_on_project(subproject)
        end

        count
      end

      # Renders the subjects of the Gantt chart, the left side.
      def subjects(options={})
        options = {:indent => 4, :render => :subject, :format => :html}.merge(options)

        output = ''
        if @project
          output << render_project(@project, options)
        else
          Project.roots.each do |project|
            output << render_project(project, options)
          end
        end

        output
      end

      # Renders the lines of the Gantt chart, the right side
      def lines(options={})
        options = {:indent => 4, :render => :line, :format => :html}.merge(options)
        output = ''

        if @project
          output << render_project(@project, options)
        else
          Project.roots.each do |project|
            output << render_project(project, options)
          end
        end
        
        output
      end

      def render_project(project, options={})
        options[:top] = 0 unless options.key? :top
        options[:indent_increment] = 20 unless options.key? :indent_increment
        options[:top_increment] = 20 unless options.key? :top_increment

        output = ''
        # Project Header
        project_header = if options[:render] == :subject
                           subject_for_project(project, options)
                         else
                           # :line
                           line_for_project(project, options)
                         end
        output << project_header if options[:format] == :html
        
        options[:top] += options[:top_increment]
        options[:indent] += options[:indent_increment]
        
        # Second, Issues without a version
        issues = project.issues.for_gantt.without_version.with_query(@query)
        if issues
          issue_rendering = render_issues(issues, options)
          output << issue_rendering if options[:format] == :html
        end

        # Third, Versions
        project.versions.sort.each do |version|
          version_rendering = render_version(version, options)
          output << version_rendering if options[:format] == :html
        end

        # Fourth, subprojects
        project.children.each do |project|
          subproject_rendering = render_project(project, options)
          output << subproject_rendering if options[:format] == :html
        end

        # Remove indent to hit the next sibling
        options[:indent] -= options[:indent_increment]
        
        output
      end

      def render_issues(issues, options={})
        output = ''
        issues.each do |i|
          issue_rendering = if options[:render] == :subject
                              subject_for_issue(i, options)
                            else
                              # :line
                              line_for_issue(i, options)
                            end
          output << issue_rendering if options[:format] == :html
          options[:top] += options[:top_increment]
        end
        output
      end

      def render_version(version, options={})
        output = ''
        # Version header
        version_rendering = if options[:render] == :subject
                              subject_for_version(version, options)
                            else
                              # :line
                              line_for_version(version, options)
                            end

        output << version_rendering if options[:format] == :html
        
        options[:top] += options[:top_increment]

        # Remove the project requirement for Versions because it will
        # restrict issues to only be on the current project.  This
        # ends up missing issues which are assigned to shared versions.
        @query.project = nil if @query.project
        
        issues = version.fixed_issues.for_gantt.with_query(@query)
        if issues
          # Indent issues
          options[:indent] += options[:indent_increment]
          output << render_issues(issues, options)
          options[:indent] -= options[:indent_increment]
        end

        output
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

          output
        when :image
          
          options[:image].fill('black')
          options[:image].stroke('transparent')
          options[:image].stroke_width(1)
          options[:image].text(options[:indent], options[:top] + 2, project.name)
        when :pdf
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
            output = ''
            i_left = ((project.start_date - self.date_from)*options[:zoom]).floor

            start_date = project.start_date
            start_date ||= self.date_from
            start_left = ((start_date - self.date_from)*options[:zoom]).floor

            i_end_date = ((project.due_date <= self.date_to) ? project.due_date : self.date_to )
            i_done_date = start_date + ((project.due_date - start_date+1)* project.completed_percent(:include_subprojects => true)/100).floor
            i_done_date = (i_done_date <= self.date_from ? self.date_from : i_done_date )
            i_done_date = (i_done_date >= self.date_to ? self.date_to : i_done_date )
            
            i_late_date = [i_end_date, Date.today].min if start_date < Date.today
            i_end = ((i_end_date - self.date_from) * options[:zoom]).floor

            i_width = (i_end - i_left + 1).floor - 2                  # total width of the issue (- 2 for left and right borders)
            d_width = ((i_done_date - start_date)*options[:zoom]).floor - 2                     # done width
            l_width = i_late_date ? ((i_late_date - start_date+1)*options[:zoom]).floor - 2 : 0 # delay width

            # Bar graphic

            # Make sure that negative i_left and i_width don't
            # overflow the subject
            if i_end > 0 && i_left <= options[:g_width]
              output << "<div style='top:#{ options[:top] }px;left:#{ start_left }px;width:#{ i_width }px;' class='task project_todo'>&nbsp;</div>"
            end
            
            if l_width > 0 && i_left <= options[:g_width]
              output << "<div style='top:#{ options[:top] }px;left:#{ start_left }px;width:#{ l_width }px;' class='task project_late'>&nbsp;</div>"
            end
            if d_width > 0 && i_left <= options[:g_width]
              output<< "<div style='top:#{ options[:top] }px;left:#{ start_left }px;width:#{ d_width }px;' class='task project_done'>&nbsp;</div>"
            end

            
            # Starting diamond
            if start_left <= options[:g_width] && start_left > 0
              output << "<div style='top:#{ options[:top] }px;left:#{ start_left }px;width:15px;' class='task project-line starting'>&nbsp;</div>"
              output << "<div style='top:#{ options[:top] }px;left:#{ start_left + 12 }px;' class='task label'>"
              output << "</div>"
            end

            # Ending diamond
            # Don't show items too far ahead
            if i_end <= options[:g_width] && i_end > 0
              output << "<div style='top:#{ options[:top] }px;left:#{ i_end }px;width:15px;' class='task project-line ending'>&nbsp;</div>"
            end

            # DIsplay the Project name and %
            if i_end <= options[:g_width]
              # Display the status even if it's floated off to the left
              status_px = i_end + 12 # 12px for the diamond
              status_px = 0 if status_px <= 0

              output << "<div style='top:#{ options[:top] }px;left:#{ status_px }px;' class='task label project-name'>"
              output << "<strong>#{h project } #{h project.completed_percent(:include_subprojects => true).to_i.to_s}%</strong>"
              output << "</div>"
            end

            output
          when :image
            options[:image].stroke('transparent')
            i_left = options[:subject_width] + ((project.due_date - self.date_from)*options[:zoom]).floor

            # Make sure negative i_left doesn't overflow the subject
            if i_left > options[:subject_width]
              options[:image].fill('blue')
              options[:image].rectangle(i_left, options[:top], i_left + 6, options[:top] - 6)        
              options[:image].fill('black')
              options[:image].text(i_left + 11, options[:top] + 1, project.name)
            end
          when :pdf
            options[:pdf].SetY(options[:top]+1.5)
            i_left = ((project.due_date - @date_from)*options[:zoom])

            # Make sure negative i_left doesn't overflow the subject
            if i_left > 0
              options[:pdf].SetX(options[:subject_width] + i_left)
              options[:pdf].SetFillColor(50,50,200)
              options[:pdf].Cell(2, 2, "", 0, 0, "", 1) 
        
              options[:pdf].SetY(options[:top]+1.5)
              options[:pdf].SetX(options[:subject_width] + i_left + 3)
              options[:pdf].Cell(30, 2, "#{project.name}")
            end
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

          output
        when :image
          options[:image].fill('black')
          options[:image].stroke('transparent')
          options[:image].stroke_width(1)
          options[:image].text(options[:indent], options[:top] + 2, version.to_s_with_project)
        when :pdf
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
            output = ''
            i_left = ((version.start_date - self.date_from)*options[:zoom]).floor
            # TODO: or version.fixed_issues.collect(&:start_date).min
            start_date = version.fixed_issues.minimum('start_date') if version.fixed_issues.present?
            start_date ||= self.date_from
            start_left = ((start_date - self.date_from)*options[:zoom]).floor

            i_end_date = ((version.due_date <= self.date_to) ? version.due_date : self.date_to )
            i_done_date = start_date + ((version.due_date - start_date+1)* version.completed_pourcent/100).floor
            i_done_date = (i_done_date <= self.date_from ? self.date_from : i_done_date )
            i_done_date = (i_done_date >= self.date_to ? self.date_to : i_done_date )
            
            i_late_date = [i_end_date, Date.today].min if start_date < Date.today

            i_width = (i_left - start_left + 1).floor - 2                  # total width of the issue (- 2 for left and right borders)
            d_width = ((i_done_date - start_date)*options[:zoom]).floor - 2                     # done width
            l_width = i_late_date ? ((i_late_date - start_date+1)*options[:zoom]).floor - 2 : 0 # delay width

            i_end = ((i_end_date - self.date_from) * options[:zoom]).floor # Ending pixel

            # Bar graphic

            # Make sure that negative i_left and i_width don't
            # overflow the subject
            if i_width > 0 && i_left <= options[:g_width]
              output << "<div style='top:#{ options[:top] }px;left:#{ start_left }px;width:#{ i_width }px;' class='task milestone_todo'>&nbsp;</div>"
            end
            if l_width > 0 && i_left <= options[:g_width]
              output << "<div style='top:#{ options[:top] }px;left:#{ start_left }px;width:#{ l_width }px;' class='task milestone_late'>&nbsp;</div>"
            end
            if d_width > 0 && i_left <= options[:g_width]
              output<< "<div style='top:#{ options[:top] }px;left:#{ start_left }px;width:#{ d_width }px;' class='task milestone_done'>&nbsp;</div>"
            end

            
            # Starting diamond
            if start_left <= options[:g_width] && start_left > 0
              output << "<div style='top:#{ options[:top] }px;left:#{ start_left }px;width:15px;' class='task milestone starting'>&nbsp;</div>"
              output << "<div style='top:#{ options[:top] }px;left:#{ start_left + 12 }px;background:#fff;' class='task'>"
              output << "</div>"
            end

            # Ending diamond
            # Don't show items too far ahead
            if i_left <= options[:g_width] && i_end > 0
              output << "<div style='top:#{ options[:top] }px;left:#{ i_end }px;width:15px;' class='task milestone ending'>&nbsp;</div>"
            end

            # Display the Version name and %
            if i_end <= options[:g_width]
              # Display the status even if it's floated off to the left
              status_px = i_end + 12 # 12px for the diamond
              status_px = 0 if status_px <= 0
              
              output << "<div style='top:#{ options[:top] }px;left:#{ status_px }px;' class='task label version-name'>"
              output << h("#{version.project} -") unless @project && @project == version.project
              output << "<strong>#{h version } #{h version.completed_pourcent.to_i.to_s}%</strong>"
              output << "</div>"
            end

            output
          when :image
            options[:image].stroke('transparent')
            i_left = options[:subject_width] + ((version.start_date - @date_from)*options[:zoom]).floor

            # Make sure negative i_left doesn't overflow the subject
            if i_left > options[:subject_width]
              options[:image].fill('green')
              options[:image].rectangle(i_left, options[:top], i_left + 6, options[:top] - 6)        
              options[:image].fill('black')
              options[:image].text(i_left + 11, options[:top] + 1, version.name)
            end
          when :pdf
            options[:pdf].SetY(options[:top]+1.5)
            i_left = ((version.start_date - @date_from)*options[:zoom]) 

            # Make sure negative i_left doesn't overflow the subject
            if i_left > 0
              options[:pdf].SetX(options[:subject_width] + i_left)
              options[:pdf].SetFillColor(50,200,50)
              options[:pdf].Cell(2, 2, "", 0, 0, "", 1) 
        
              options[:pdf].SetY(options[:top]+1.5)
              options[:pdf].SetX(options[:subject_width] + i_left + 3)
              options[:pdf].Cell(30, 2, "#{version.name}")
            end
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
            output << ":"
            output << h(issue.subject)
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
          output
        when :image
          options[:image].fill('black')
          options[:image].stroke('transparent')
          options[:image].stroke_width(1)
          options[:image].text(options[:indent], options[:top] + 2, issue.subject)
        when :pdf
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
            output = ''
            # Handle nil start_dates, rare but can happen.
            i_start_date =  if issue.start_date && issue.start_date >= self.date_from
                              issue.start_date
                            else
                              self.date_from
                            end

            i_end_date = ((issue.due_before && issue.due_before <= self.date_to) ? issue.due_before : self.date_to )
            i_done_date = i_start_date + ((issue.due_before - i_start_date+1)*issue.done_ratio/100).floor
            i_done_date = (i_done_date <= self.date_from ? self.date_from : i_done_date )
            i_done_date = (i_done_date >= self.date_to ? self.date_to : i_done_date )
            
            i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
            
            i_left = ((i_start_date - self.date_from)*options[:zoom]).floor 	
            i_width = ((i_end_date - i_start_date + 1)*options[:zoom]).floor - 2                  # total width of the issue (- 2 for left and right borders)
            d_width = ((i_done_date - i_start_date)*options[:zoom]).floor - 2                     # done width
            l_width = i_late_date ? ((i_late_date - i_start_date+1)*options[:zoom]).floor - 2 : 0 # delay width
            css = "task " + (issue.leaf? ? 'leaf' : 'parent')
            
            # Make sure that negative i_left and i_width don't
            # overflow the subject
            if i_width > 0
              output << "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ i_width }px;' class='#{css} task_todo'>&nbsp;</div>"
            end
            if l_width > 0
              output << "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ l_width }px;' class='#{css} task_late'>&nbsp;</div>"
            end
            if d_width > 0
              output<< "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ d_width }px;' class='#{css} task_done'>&nbsp;</div>"
            end

            # Display the status even if it's floated off to the left
            status_px = i_left + i_width + 5
            status_px = 5 if status_px <= 0
            
            output << "<div style='top:#{ options[:top] }px;left:#{ status_px }px;' class='#{css} label issue-name'>"
            output << issue.status.name
            output << ' '
            output << (issue.done_ratio).to_i.to_s
            output << "%"
            output << "</div>"

            output << "<div class='tooltip' style='position: absolute;top:#{ options[:top] }px;left:#{ i_left }px;width:#{ i_width }px;height:12px;'>"
            output << '<span class="tip">'
            output << view.render_issue_tooltip(issue)
            output << "</span></div>"
            output
          
          when :image
            # Handle nil start_dates, rare but can happen.
            i_start_date =  if issue.start_date && issue.start_date >= @date_from
                              issue.start_date
                            else
                              @date_from
                            end

            i_end_date = (issue.due_before <= date_to ? issue.due_before : date_to )        
            i_done_date = i_start_date + ((issue.due_before - i_start_date+1)*issue.done_ratio/100).floor
            i_done_date = (i_done_date <= @date_from ? @date_from : i_done_date )
            i_done_date = (i_done_date >= date_to ? date_to : i_done_date )        
            i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
            
            i_left = options[:subject_width] + ((i_start_date - @date_from)*options[:zoom]).floor 	
            i_width = ((i_end_date - i_start_date + 1)*options[:zoom]).floor                  # total width of the issue
            d_width = ((i_done_date - i_start_date)*options[:zoom]).floor                     # done width
            l_width = i_late_date ? ((i_late_date - i_start_date+1)*options[:zoom]).floor : 0 # delay width

            
            # Make sure that negative i_left and i_width don't
            # overflow the subject
            if i_width > 0
              options[:image].fill('grey')
              options[:image].rectangle(i_left, options[:top], i_left + i_width, options[:top] - 6)
              options[:image].fill('red')
              options[:image].rectangle(i_left, options[:top], i_left + l_width, options[:top] - 6) if l_width > 0
              options[:image].fill('blue')
              options[:image].rectangle(i_left, options[:top], i_left + d_width, options[:top] - 6) if d_width > 0
            end

            # Show the status and % done next to the subject if it overflows
            options[:image].fill('black')
            if i_width > 0
              options[:image].text(i_left + i_width + 5,options[:top] + 1, "#{issue.status.name} #{issue.done_ratio}%")
            else
              options[:image].text(options[:subject_width] + 5,options[:top] + 1, "#{issue.status.name} #{issue.done_ratio}%")            
            end

          when :pdf
            options[:pdf].SetY(options[:top]+1.5)
            # Handle nil start_dates, rare but can happen.
            i_start_date =  if issue.start_date && issue.start_date >= @date_from
                          issue.start_date
                        else
                          @date_from
                        end

            i_end_date = (issue.due_before <= @date_to ? issue.due_before : @date_to )
            
            i_done_date = i_start_date + ((issue.due_before - i_start_date+1)*issue.done_ratio/100).floor
            i_done_date = (i_done_date <= @date_from ? @date_from : i_done_date )
            i_done_date = (i_done_date >= @date_to ? @date_to : i_done_date )
            
            i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
            
            i_left = ((i_start_date - @date_from)*options[:zoom]) 
            i_width = ((i_end_date - i_start_date + 1)*options[:zoom])
            d_width = ((i_done_date - i_start_date)*options[:zoom])
            l_width = ((i_late_date - i_start_date+1)*options[:zoom]) if i_late_date
            l_width ||= 0

            # Make sure that negative i_left and i_width don't
            # overflow the subject
            if i_width > 0
              options[:pdf].SetX(options[:subject_width] + i_left)
              options[:pdf].SetFillColor(200,200,200)
              options[:pdf].Cell(i_width, 2, "", 0, 0, "", 1)
            end
          
            if l_width > 0
              options[:pdf].SetY(options[:top]+1.5)
              options[:pdf].SetX(options[:subject_width] + i_left)
              options[:pdf].SetFillColor(255,100,100)
              options[:pdf].Cell(l_width, 2, "", 0, 0, "", 1)
            end 
            if d_width > 0
              options[:pdf].SetY(options[:top]+1.5)
              options[:pdf].SetX(options[:subject_width] + i_left)
              options[:pdf].SetFillColor(100,100,255)
              options[:pdf].Cell(d_width, 2, "", 0, 0, "", 1)
            end

            options[:pdf].SetY(options[:top]+1.5)

            # Make sure that negative i_left and i_width don't
            # overflow the subject
            if (i_left + i_width) >= 0
              options[:pdf].SetX(options[:subject_width] + i_left + i_width)
            else
              options[:pdf].SetX(options[:subject_width])
            end
            options[:pdf].Cell(30, 2, "#{issue.status} #{issue.done_ratio}%")
          end
        else
          ActiveRecord::Base.logger.debug "GanttHelper#line_for_issue was not given an issue with a due_before"
          ''
        end
      end

      # Generates a gantt image
      # Only defined if RMagick is avalaible
      def to_image(project, format='PNG')
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
        pdf_subjects_and_lines(pdf, {
                                 :top => top,
                                 :zoom => zoom,
                                 :subject_width => subject_width,
                                 :g_width => g_width
                               })

        
        pdf.Line(15, top, subject_width+g_width, top)
        pdf.Output

        
      end
      
      private

      # Renders both the subjects and lines of the Gantt chart for the
      # PDF format
      def pdf_subjects_and_lines(pdf, options = {})
        subject_options = {:indent => 0, :indent_increment => 5, :top_increment => 3, :render => :subject, :format => :pdf, :pdf => pdf}.merge(options)
        line_options = {:indent => 0, :indent_increment => 5, :top_increment => 3, :render => :line, :format => :pdf, :pdf => pdf}.merge(options)

        if @project
          render_project(@project, subject_options)
          render_project(@project, line_options)
        else
          Project.roots.each do |project|
            render_project(project, subject_options)
            render_project(project, line_options)
          end
        end
      end

    end
  end
end
