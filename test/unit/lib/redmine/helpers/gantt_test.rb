# redMine - project management software
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

require File.expand_path('../../../../../test_helper', __FILE__)

class Redmine::Helpers::GanttTest < ActiveSupport::TestCase
  # Utility methods and classes so assert_select can be used.
  class GanttViewTest < ActionView::Base
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TextHelper
    include ActionController::UrlWriter
    include ApplicationHelper
    include ProjectsHelper
    include IssuesHelper
    
    def self.default_url_options
      {:only_path => true }
    end

  end

  include ActionController::Assertions::SelectorAssertions

  def setup
    @response = ActionController::TestResponse.new
    # Fixtures
    ProjectCustomField.delete_all
    Project.destroy_all

    User.current = User.find(1)
  end

  def build_view
    @view = GanttViewTest.new
  end

  def html_document
    HTML::Document.new(@response.body)
  end

  # Creates a Gantt chart for a 4 week span
  def create_gantt(project=Project.generate!, options={})
    @project = project
    @gantt = Redmine::Helpers::Gantt.new(options)
    @gantt.project = @project
    @gantt.query = Query.generate_default!(:project => @project)
    @gantt.view = build_view
    @gantt.instance_variable_set('@date_from', options[:date_from] || 2.weeks.ago.to_date)
    @gantt.instance_variable_set('@date_to', options[:date_to] || 2.weeks.from_now.to_date)
  end

  context "#number_of_rows" do

    context "with one project" do
      should "return the number of rows just for that project"
    end

    context "with no project" do
      should "return the total number of rows for all the projects, resursively"
    end

    should "not exceed max_rows option" do
      p = Project.generate!
      5.times do
        Issue.generate_for_project!(p)
      end
      
      create_gantt(p)
      @gantt.render
      assert_equal 6, @gantt.number_of_rows
      assert !@gantt.truncated

      create_gantt(p, :max_rows => 3)
      @gantt.render
      assert_equal 3, @gantt.number_of_rows
      assert @gantt.truncated
    end
  end

  context "#number_of_rows_on_project" do
    setup do
      create_gantt
    end
    
    should "clear the @query.project so cross-project issues and versions can be counted" do
      assert @gantt.query.project
      @gantt.number_of_rows_on_project(@project)
      assert_nil @gantt.query.project
    end

    should "count 1 for the project itself" do
      assert_equal 1, @gantt.number_of_rows_on_project(@project)
    end

    should "count the number of issues without a version" do
      @project.issues << Issue.generate_for_project!(@project, :fixed_version => nil)
      assert_equal 2, @gantt.number_of_rows_on_project(@project)
    end

    should "count the number of versions" do
      @project.versions << Version.generate!
      @project.versions << Version.generate!
      assert_equal 3, @gantt.number_of_rows_on_project(@project)
    end

    should "count the number of issues on versions, including cross-project" do
      version = Version.generate!
      @project.versions << version
      @project.issues << Issue.generate_for_project!(@project, :fixed_version => version)
      
      assert_equal 3, @gantt.number_of_rows_on_project(@project)
    end
    
    should "recursive and count the number of rows on each subproject" do
      @project.versions << Version.generate! # +1

      @subproject = Project.generate!(:enabled_module_names => ['issue_tracking']) # +1
      @subproject.set_parent!(@project)
      @subproject.issues << Issue.generate_for_project!(@subproject) # +1
      @subproject.issues << Issue.generate_for_project!(@subproject) # +1

      @subsubproject = Project.generate!(:enabled_module_names => ['issue_tracking']) # +1
      @subsubproject.set_parent!(@subproject)
      @subsubproject.issues << Issue.generate_for_project!(@subsubproject) # +1

      assert_equal 7, @gantt.number_of_rows_on_project(@project) # +1 for self
    end
  end

  # TODO: more of an integration test
  context "#subjects" do
    setup do
      create_gantt
      @project.enabled_module_names = [:issue_tracking]
      @tracker = Tracker.generate!
      @project.trackers << @tracker
      @version = Version.generate!(:effective_date => 1.week.from_now.to_date, :sharing => 'none')
      @project.versions << @version

      @issue = Issue.generate!(:fixed_version => @version,
                               :subject => "gantt#line_for_project",
                               :tracker => @tracker,
                               :project => @project,
                               :done_ratio => 30,
                               :start_date => Date.yesterday,
                               :due_date => 1.week.from_now.to_date)
      @project.issues << @issue

      @response.body = @gantt.subjects
    end

    context "project" do
      should "be rendered" do
        assert_select "div.project-name a", /#{@project.name}/
      end

      should "have an indent of 4" do
        assert_select "div.project-name[style*=left:4px]"
      end
    end

    context "version" do
      should "be rendered" do
        assert_select "div.version-name a", /#{@version.name}/
      end

      should "be indented 24 (one level)" do
        assert_select "div.version-name[style*=left:24px]"
      end
    end

    context "issue" do
      should "be rendered" do
        assert_select "div.issue-subject", /#{@issue.subject}/
      end

      should "be indented 44 (two levels)" do
        assert_select "div.issue-subject[style*=left:44px]"
      end
    end
  end

  context "#lines" do
    setup do
      create_gantt
      @project.enabled_module_names = [:issue_tracking]
      @tracker = Tracker.generate!
      @project.trackers << @tracker
      @version = Version.generate!(:effective_date => 1.week.from_now.to_date)
      @project.versions << @version
      @issue = Issue.generate!(:fixed_version => @version,
                               :subject => "gantt#line_for_project",
                               :tracker => @tracker,
                               :project => @project,
                               :done_ratio => 30,
                               :start_date => Date.yesterday,
                               :due_date => 1.week.from_now.to_date)
      @project.issues << @issue

      @response.body = @gantt.lines
    end

    context "project" do
      should "be rendered" do
        assert_select "div.project_todo"
        assert_select "div.project-line.starting"
        assert_select "div.project-line.ending"
        assert_select "div.label.project-name", /#{@project.name}/
      end
    end

    context "version" do
      should "be rendered" do
        assert_select "div.milestone_todo"
        assert_select "div.milestone.starting"
        assert_select "div.milestone.ending"
        assert_select "div.label.version-name", /#{@version.name}/
      end
    end

    context "issue" do
      should "be rendered" do
        assert_select "div.task_todo"
        assert_select "div.task.label", /#{@issue.done_ratio}/
        assert_select "div.tooltip", /#{@issue.subject}/
      end
    end
  end

  context "#render_project" do
    should "be tested"
  end

  context "#render_issues" do
    should "be tested"
  end

  context "#render_version" do
    should "be tested"
  end

  context "#subject_for_project" do
    setup do
      create_gantt
    end
    
    context ":html format" do
      should "add an absolute positioned div" do
        @response.body = @gantt.subject_for_project(@project, {:format => :html})
        assert_select "div[style*=absolute]"
      end

      should "use the indent option to move the div to the right" do
        @response.body = @gantt.subject_for_project(@project, {:format => :html, :indent => 40})
        assert_select "div[style*=left:40]"
      end

      should "include the project name" do
        @response.body = @gantt.subject_for_project(@project, {:format => :html})
        assert_select 'div', :text => /#{@project.name}/
      end

      should "include a link to the project" do
        @response.body = @gantt.subject_for_project(@project, {:format => :html})
        assert_select 'a[href=?]', "/projects/#{@project.identifier}", :text => /#{@project.name}/
      end

      should "style overdue projects" do
        @project.enabled_module_names = [:issue_tracking]
        @project.versions << Version.generate!(:effective_date => Date.yesterday)

        assert @project.overdue?, "Need an overdue project for this test"
        @response.body = @gantt.subject_for_project(@project, {:format => :html})

        assert_select 'div span.project-overdue'
      end


    end

    should "test the PNG format"
    should "test the PDF format"
  end

  context "#line_for_project" do
    setup do
      create_gantt
      @project.enabled_module_names = [:issue_tracking]
      @tracker = Tracker.generate!
      @project.trackers << @tracker
      @version = Version.generate!(:effective_date => Date.yesterday)
      @project.versions << @version

      @project.issues << Issue.generate!(:fixed_version => @version,
                                         :subject => "gantt#line_for_project",
                                         :tracker => @tracker,
                                         :project => @project,
                                         :done_ratio => 30,
                                         :start_date => Date.yesterday,
                                         :due_date => 1.week.from_now.to_date)
    end

    context ":html format" do
      context "todo line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project_todo[style*=left:52px]"
        end

        should "be the total width of the project" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project_todo[style*=width:31px]"
        end

      end

      context "late line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project_late[style*=left:52px]"
        end

        should "be the total delayed width of the project" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project_late[style*=width:6px]"
        end
      end

      context "done line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project_done[style*=left:52px]"
        end

        should "Be the total done width of the project"  do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project_done[style*=left:52px]"
        end
      end

      context "starting marker" do
        should "not appear if the starting point is off the gantt chart" do
          # Shift the date range of the chart
          @gantt.instance_variable_set('@date_from', Date.today)

          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project-line.starting", false
        end

        should "appear at the starting point" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project-line.starting[style*=left:52px]"
        end
      end

      context "ending marker" do
        should "not appear if the starting point is off the gantt chart" do
          # Shift the date range of the chart
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project-line.ending", false

        end

        should "appear at the end of the date range" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project-line.ending[style*=left:84px]"
        end
      end
      
      context "status content" do
        should "appear at the far left, even if it's far in the past" do
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project-name", /#{@project.name}/
        end

        should "show the project name" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project-name", /#{@project.name}/
        end

        should "show the percent complete" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project-name", /0%/
        end
      end
    end

    should "test the PNG format"
    should "test the PDF format"
  end

  context "#subject_for_version" do
    setup do
      create_gantt
      @project.enabled_module_names = [:issue_tracking]
      @tracker = Tracker.generate!
      @project.trackers << @tracker
      @version = Version.generate!(:effective_date => Date.yesterday)
      @project.versions << @version

      @project.issues << Issue.generate!(:fixed_version => @version,
                                         :subject => "gantt#subject_for_version",
                                         :tracker => @tracker,
                                         :project => @project,
                                         :start_date => Date.today)

    end

    context ":html format" do
      should "add an absolute positioned div" do
        @response.body = @gantt.subject_for_version(@version, {:format => :html})
        assert_select "div[style*=absolute]"
      end

      should "use the indent option to move the div to the right" do
        @response.body = @gantt.subject_for_version(@version, {:format => :html, :indent => 40})
        assert_select "div[style*=left:40]"
      end

      should "include the version name" do
        @response.body = @gantt.subject_for_version(@version, {:format => :html})
        assert_select 'div', :text => /#{@version.name}/
      end

      should "include a link to the version" do
        @response.body = @gantt.subject_for_version(@version, {:format => :html})
        assert_select 'a[href=?]', Regexp.escape("/versions/show/#{@version.to_param}"), :text => /#{@version.name}/
      end

      should "style late versions" do
        assert @version.overdue?, "Need an overdue version for this test"
        @response.body = @gantt.subject_for_version(@version, {:format => :html})

        assert_select 'div span.version-behind-schedule'
      end

      should "style behind schedule versions" do
        assert @version.behind_schedule?, "Need a behind schedule version for this test"
        @response.body = @gantt.subject_for_version(@version, {:format => :html})

        assert_select 'div span.version-behind-schedule'
      end
    end
    should "test the PNG format"
    should "test the PDF format"
  end

  context "#line_for_version" do
    setup do
      create_gantt
      @project.enabled_module_names = [:issue_tracking]
      @tracker = Tracker.generate!
      @project.trackers << @tracker
      @version = Version.generate!(:effective_date => 1.week.from_now.to_date)
      @project.versions << @version

      @project.issues << Issue.generate!(:fixed_version => @version,
                                         :subject => "gantt#line_for_project",
                                         :tracker => @tracker,
                                         :project => @project,
                                         :done_ratio => 30,
                                         :start_date => Date.yesterday,
                                         :due_date => 1.week.from_now.to_date)
    end

    context ":html format" do
      context "todo line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone_todo[style*=left:52px]"
        end

        should "be the total width of the version" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone_todo[style*=width:31px]"
        end

      end

      context "late line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone_late[style*=left:52px]"
        end

        should "be the total delayed width of the version" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone_late[style*=width:6px]"
        end
      end

      context "done line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone_done[style*=left:52px]"
        end

        should "Be the total done width of the version"  do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone_done[style*=left:52px]"
        end
      end

      context "starting marker" do
        should "not appear if the starting point is off the gantt chart" do
          # Shift the date range of the chart
          @gantt.instance_variable_set('@date_from', Date.today)

          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone.starting", false
        end

        should "appear at the starting point" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone.starting[style*=left:52px]"
        end
      end

      context "ending marker" do
        should "not appear if the starting point is off the gantt chart" do
          # Shift the date range of the chart
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone.ending", false

        end

        should "appear at the end of the date range" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.milestone.ending[style*=left:84px]"
        end
      end
      
      context "status content" do
        should "appear at the far left, even if it's far in the past" do
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version-name", /#{@version.name}/
        end

        should "show the version name" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version-name", /#{@version.name}/
        end

        should "show the percent complete" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version-name", /30%/
        end
      end
    end

    should "test the PNG format"
    should "test the PDF format"
  end

  context "#subject_for_issue" do
    setup do
      create_gantt
      @project.enabled_module_names = [:issue_tracking]
      @tracker = Tracker.generate!
      @project.trackers << @tracker

      @issue = Issue.generate!(:subject => "gantt#subject_for_issue",
                               :tracker => @tracker,
                               :project => @project,
                               :start_date => 3.days.ago.to_date,
                               :due_date => Date.yesterday)
      @project.issues << @issue

    end

    context ":html format" do
      should "add an absolute positioned div" do
        @response.body = @gantt.subject_for_issue(@issue, {:format => :html})
        assert_select "div[style*=absolute]"
      end

      should "use the indent option to move the div to the right" do
        @response.body = @gantt.subject_for_issue(@issue, {:format => :html, :indent => 40})
        assert_select "div[style*=left:40]"
      end

      should "include the issue subject" do
        @response.body = @gantt.subject_for_issue(@issue, {:format => :html})
        assert_select 'div', :text => /#{@issue.subject}/
      end

      should "include a link to the issue" do
        @response.body = @gantt.subject_for_issue(@issue, {:format => :html})
        assert_select 'a[href=?]', Regexp.escape("/issues/#{@issue.to_param}"), :text => /#{@tracker.name} ##{@issue.id}/
      end

      should "style overdue issues" do
        assert @issue.overdue?, "Need an overdue issue for this test"
        @response.body = @gantt.subject_for_issue(@issue, {:format => :html})

        assert_select 'div span.issue-overdue'
      end

    end
    should "test the PNG format"
    should "test the PDF format"
  end

  context "#line_for_issue" do
    setup do
      create_gantt
      @project.enabled_module_names = [:issue_tracking]
      @tracker = Tracker.generate!
      @project.trackers << @tracker
      @version = Version.generate!(:effective_date => 1.week.from_now.to_date)
      @project.versions << @version
      @issue = Issue.generate!(:fixed_version => @version,
                               :subject => "gantt#line_for_project",
                               :tracker => @tracker,
                               :project => @project,
                               :done_ratio => 30,
                               :start_date => 1.week.ago.to_date,
                               :due_date => 1.week.from_now.to_date)
      @project.issues << @issue
    end

    context ":html format" do
      context "todo line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task_todo[style*=left:28px]", true, @response.body
        end

        should "be the total width of the issue" do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task_todo[style*=width:58px]", true, @response.body
        end

      end

      context "late line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task_late[style*=left:28px]", true, @response.body
        end

        should "be the total delayed width of the issue" do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task_late[style*=width:30px]", true, @response.body
        end
      end

      context "done line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task_done[style*=left:28px]", true, @response.body
        end

        should "Be the total done width of the issue"  do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task_done[style*=width:18px]", true, @response.body
        end

        should "not be the total done width if the chart starts after issue start date"  do
          create_gantt(@project, :date_from => 5.days.ago.to_date)
          
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task_done[style*=left:0px]", true, @response.body
          assert_select "div.task_done[style*=width:10px]", true, @response.body
        end
      end

      context "status content" do
        should "appear at the far left, even if it's far in the past" do
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task.label", true, @response.body
        end

        should "show the issue status" do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task.label", /#{@issue.status.name}/
        end

        should "show the percent complete" do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task.label", /30%/
        end
      end
    end

    should "have an issue tooltip" do
      @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
      assert_select "div.tooltip", /#{@issue.subject}/
    end

    should "test the PNG format"
    should "test the PDF format"
  end

  context "#to_image" do
    should "be tested"
  end

  context "#to_pdf" do
    should "be tested"
  end
  
end
