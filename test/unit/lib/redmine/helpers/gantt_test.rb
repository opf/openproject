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

    should "count 0 for an empty the project" do
      assert_equal 0, @gantt.number_of_rows_on_project(@project)
    end

    should "count the number of issues without a version" do
      @project.issues << Issue.generate_for_project!(@project, :fixed_version => nil)
      assert_equal 2, @gantt.number_of_rows_on_project(@project)
    end

    should "count the number of issues on versions, including cross-project" do
      version = Version.generate!
      @project.versions << version
      @project.issues << Issue.generate_for_project!(@project, :fixed_version => version)
      
      assert_equal 3, @gantt.number_of_rows_on_project(@project)
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
    end
  
    context "project" do
      should "be rendered" do
        @response.body = @gantt.subjects
        assert_select "div.project-name a", /#{@project.name}/
      end
  
      should "have an indent of 4" do
        @response.body = @gantt.subjects
        assert_select "div.project-name[style*=left:4px]"
      end
    end
  
    context "version" do
      should "be rendered" do
        @response.body = @gantt.subjects
        assert_select "div.version-name a", /#{@version.name}/
      end
  
      should "be indented 24 (one level)" do
        @response.body = @gantt.subjects
        assert_select "div.version-name[style*=left:24px]"
      end
      
      context "without assigned issues" do
        setup do
          @version = Version.generate!(:effective_date => 2.week.from_now.to_date, :sharing => 'none', :name => 'empty_version')
          @project.versions << @version
        end
      
        should "not be rendered" do
          @response.body = @gantt.subjects
          assert_select "div.version-name a", :text => /#{@version.name}/, :count => 0
        end
      end
    end
  
    context "issue" do
      should "be rendered" do
        @response.body = @gantt.subjects
        assert_select "div.issue-subject", /#{@issue.subject}/
      end
  
      should "be indented 44 (two levels)" do
        @response.body = @gantt.subjects
        assert_select "div.issue-subject[style*=left:44px]"
      end
      
      context "assigned to a shared version of another project" do
        setup do
          p = Project.generate!
          p.trackers << @tracker
          p.enabled_module_names = [:issue_tracking]
          @shared_version = Version.generate!(:sharing => 'system')
          p.versions << @shared_version
          # Reassign the issue to a shared version of another project
          
          @issue = Issue.generate!(:fixed_version => @shared_version,
                                   :subject => "gantt#assigned_to_shared_version",
                                   :tracker => @tracker,
                                   :project => @project,
                                   :done_ratio => 30,
                                   :start_date => Date.yesterday,
                                   :due_date => 1.week.from_now.to_date)
          @project.issues << @issue
        end
        
        should "be rendered" do
          @response.body = @gantt.subjects
          assert_select "div.issue-subject", /#{@issue.subject}/
        end
      end
      
      context "with subtasks" do
        setup do
          attrs = {:project => @project, :tracker => @tracker, :fixed_version => @version}
          @child1 = Issue.generate!(attrs.merge(:subject => 'child1', :parent_issue_id => @issue.id, :start_date => Date.yesterday, :due_date => 2.day.from_now.to_date))
          @child2 = Issue.generate!(attrs.merge(:subject => 'child2', :parent_issue_id => @issue.id, :start_date => Date.today, :due_date => 1.week.from_now.to_date))
          @grandchild = Issue.generate!(attrs.merge(:subject => 'grandchild', :parent_issue_id => @child1.id, :start_date => Date.yesterday, :due_date => 2.day.from_now.to_date))
        end
        
        should "indent subtasks" do
          @response.body = @gantt.subjects
          # parent task 44px
          assert_select "div.issue-subject[style*=left:44px]", /#{@issue.subject}/
          # children 64px
          assert_select "div.issue-subject[style*=left:64px]", /child1/
          assert_select "div.issue-subject[style*=left:64px]", /child2/
          # grandchild 84px
          assert_select "div.issue-subject[style*=left:84px]", /grandchild/, @response.body
        end
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
        assert_select "div.project.task_todo"
        assert_select "div.project.starting"
        assert_select "div.project.ending"
        assert_select "div.label.project", /#{@project.name}/
      end
    end

    context "version" do
      should "be rendered" do
        assert_select "div.version.task_todo"
        assert_select "div.version.starting"
        assert_select "div.version.ending"
        assert_select "div.label.version", /#{@version.name}/
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
                                         :start_date => 1.week.ago.to_date,
                                         :due_date => 1.week.from_now.to_date)
    end

    context ":html format" do
      context "todo line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.task_todo[style*=left:28px]", true, @response.body
        end

        should "be the total width of the project" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.task_todo[style*=width:58px]", true, @response.body
        end

      end

      context "late line" do
        should_eventually "start from the starting point on the left" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.task_late[style*=left:28px]", true, @response.body
        end

        should_eventually "be the total delayed width of the project" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.task_late[style*=width:30px]", true, @response.body
        end
      end

      context "done line" do
        should_eventually "start from the starting point on the left" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.task_done[style*=left:28px]", true, @response.body
        end

        should_eventually "Be the total done width of the project"  do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.task_done[style*=width:18px]", true, @response.body
        end
      end

      context "starting marker" do
        should "not appear if the starting point is off the gantt chart" do
          # Shift the date range of the chart
          @gantt.instance_variable_set('@date_from', Date.today)

          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.starting", false, @response.body
        end

        should "appear at the starting point" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.starting[style*=left:28px]", true, @response.body
        end
      end

      context "ending marker" do
        should "not appear if the starting point is off the gantt chart" do
          # Shift the date range of the chart
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.ending", false, @response.body

        end

        should "appear at the end of the date range" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.ending[style*=left:88px]", true, @response.body
        end
      end
      
      context "status content" do
        should "appear at the far left, even if it's far in the past" do
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.label", /#{@project.name}/
        end

        should "show the project name" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.label", /#{@project.name}/
        end

        should_eventually "show the percent complete" do
          @response.body = @gantt.line_for_project(@project, {:format => :html, :zoom => 4})
          assert_select "div.project.label", /0%/
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
                                         :start_date => 1.week.ago.to_date,
                                         :due_date => 1.week.from_now.to_date)
    end

    context ":html format" do
      context "todo line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.task_todo[style*=left:28px]", true, @response.body
        end

        should "be the total width of the version" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.task_todo[style*=width:58px]", true, @response.body
        end

      end

      context "late line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.task_late[style*=left:28px]", true, @response.body
        end

        should "be the total delayed width of the version" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.task_late[style*=width:30px]", true, @response.body
        end
      end

      context "done line" do
        should "start from the starting point on the left" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.task_done[style*=left:28px]", true, @response.body
        end

        should "be the total done width of the version"  do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.task_done[style*=width:16px]", true, @response.body
        end
      end

      context "starting marker" do
        should "not appear if the starting point is off the gantt chart" do
          # Shift the date range of the chart
          @gantt.instance_variable_set('@date_from', Date.today)

          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.starting", false
        end

        should "appear at the starting point" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.starting[style*=left:28px]", true, @response.body
        end
      end

      context "ending marker" do
        should "not appear if the starting point is off the gantt chart" do
          # Shift the date range of the chart
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.ending", false

        end

        should "appear at the end of the date range" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.ending[style*=left:88px]", true, @response.body
        end
      end
      
      context "status content" do
        should "appear at the far left, even if it's far in the past" do
          @gantt.instance_variable_set('@date_to', 2.weeks.ago.to_date)

          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.label", /#{@version.name}/
        end

        should "show the version name" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.label", /#{@version.name}/
        end

        should "show the percent complete" do
          @response.body = @gantt.line_for_version(@version, {:format => :html, :zoom => 4})
          assert_select "div.version.label", /30%/
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

        should "be the total done width of the issue"  do
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          # 15 days * 4 px * 30% - 2 px for borders = 16 px
          assert_select "div.task_done[style*=width:16px]", true, @response.body
        end

        should "not be the total done width if the chart starts after issue start date"  do
          create_gantt(@project, :date_from => 5.days.ago.to_date)
          
          @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
          assert_select "div.task_done[style*=left:0px]", true, @response.body
          assert_select "div.task_done[style*=width:8px]", true, @response.body
        end
        
        context "for completed issue" do
          setup do
            @issue.done_ratio = 100
          end

          should "be the total width of the issue"  do
            @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
            assert_select "div.task_done[style*=width:58px]", true, @response.body
          end
  
          should "be the total width of the issue with due_date=start_date"  do
            @issue.due_date = @issue.start_date
            @response.body = @gantt.line_for_issue(@issue, {:format => :html, :zoom => 4})
            assert_select "div.task_done[style*=width:2px]", true, @response.body
          end
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
