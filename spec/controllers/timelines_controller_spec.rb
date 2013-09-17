#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

require File.expand_path('../../spec_helper', __FILE__)

describe TimelinesController do
  # ===========================================================
  # Helpers
  def self.become_admin
    let(:current_user) { FactoryGirl.create(:admin) }
  end

  def self.become_non_member
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      current_user.memberships.select {|m| m.project_id == project.id}.each(&:destroy)
    end
  end

  def self.become_member_with_all_permissions
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:view_timelines, :edit_timelines, :delete_timelines])
      member = FactoryGirl.build(:member, :user => current_user, :project => project)
      member.roles = [role]
      member.save!
    end
  end

  def self.become_member_with_view_permissions
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:view_timelines])
      member = FactoryGirl.build(:member, :user => current_user, :project => project)
      member.roles = [role]
      member.save!
    end
  end

  def self.become_member_with_edit_permissions
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:edit_timelines])
      member = FactoryGirl.build(:member, :user => current_user, :project => project)
      member.roles = [role]
      member.save!
    end
  end

  def self.become_member_with_delete_permissions
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:delete_timelines])
      member = FactoryGirl.build(:member, :user => current_user, :project => project)
      member.roles = [role]
      member.save!
    end
  end


  before do
    User.stub(:current).and_return current_user
  end

  shared_examples_for 'all actions related to all timelines within a project' do
    describe 'w/o a given project' do
      become_admin

      it 'renders a 404 Not Found page' do
        fetch

        response.response_code.should == 404
      end
    end

    describe 'w/ an unknown project' do
      become_admin

      it 'renders a 404 Not Found page' do
        fetch :project_id => '4711'

        response.response_code.should == 404
      end
    end

    describe 'w/ a known project' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          fetch :project_id => project.identifier

          response.response_code.should == 403
        end
      end
    end
  end

  shared_examples_for 'all actions related to an existing timeline' do
    become_admin

    describe 'w/o a valid timelines id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          fetch :id => '4711'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          fetch :project_id => '4711', :id => '1337'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            fetch :project_id => project.id, :id => '1337'

            response.response_code.should === 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_all_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            lambda do
              fetch :project_id => project.id, :id => '1337'
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid timelines id' do
      let(:project)  { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:timeline) { FactoryGirl.create(:timelines, :project_id => project.id, :name => 'b') }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          fetch :id => timeline.id

          response.response_code.should == 404
        end
      end

      describe 'w/ a different project' do
        let(:other_project)  { FactoryGirl.create(:project, :identifier => 'other') }

        it 'raises ActiveRecord::RecordNotFound errors' do
          lambda do
            fetch :project_id => other_project.identifier,:id => timeline.id
          end.should raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'w/ a proper project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            fetch :project_id => project.id, :id => timeline.id

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_all_permissions

          it 'assigns the timeline' do
            fetch :project_id => project.id, :id => timeline.id
            assigns(:timeline).should == timeline
          end
        end
      end
    end
  end


  describe 'index.html' do
    def fetch(options = {})
      get 'index', options
    end
    it_should_behave_like 'all actions related to all timelines within a project'

    describe 'w/ a known project' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

      describe 'w/ the current user having view_timelines permissions' do
        become_member_with_all_permissions

        describe 'w/o any timelines within the project' do
          it 'redirects to /new' do
            fetch :project_id => project.identifier
            response.should redirect_to :action => 'new',
                                        :project_id => project.identifier
          end
        end

        describe 'w/ 3 timelines within the project' do
          before do
            @created_timelines = [
              FactoryGirl.create(:timelines, :project_id => project.id, :name => 'b'),
              FactoryGirl.create(:timelines, :project_id => project.id, :name => 'c'),
              FactoryGirl.create(:timelines, :project_id => project.id, :name => 'a')
            ]
          end

          it 'redirects to first (in alphabetical order) timeline' do
            fetch :project_id => project.identifier
            response.should redirect_to :action => 'show',
                                        :id => @created_timelines.last.id,
                                        :project_id => project.identifier

          end
        end
      end
    end
  end

  describe 'new.html' do
    def fetch(options = {})
      get 'new', options
    end

    it_should_behave_like 'all actions related to all timelines within a project'

    describe 'w/ a known project' do
      become_member_with_edit_permissions

      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

      it 'renders the new template' do
        fetch :project_id => project.id
        response.should render_template('timelines/new', :formats => ["html"], :layout => :base)
      end

      it 'assigns a new timeline instance for the current project' do
        fetch :project_id => project.id

        assigns[:timeline].should be_new_record
        assigns[:timeline].project.should == project
      end
    end
  end

  describe 'create.html' do
    def fetch(options = {})
      post 'create', options
    end

    it_should_behave_like 'all actions related to all timelines within a project'

    describe 'w/ a known project' do
      become_member_with_edit_permissions

      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

      describe 'w/ proper parameters' do
        it 'create a new timelines instance' do
          fetch :project_id => project.id, :timeline => {:name => 'bb'}

          project.timelines.reload
          project.timelines.first.name.should == 'bb'
        end

        it 'redirects to show' do
          fetch :project_id => project.id, :timeline => {:name => 'bb'}

          timeline = project.timelines.reload.first
          response.should redirect_to(project_timeline_path(project, timeline))
        end

        it 'notifies the user about the successful creation' do
          fetch :project_id => project.id, :timeline => {:name => 'bb'}

          flash[:notice].should =~ /success/i
        end
      end

      describe 'w/o proper parameters' do
        it 'does not save the new timelines instance' do
          fetch :project_id => project.id, :timeline => {:name => ''}

          project.timelines.reload.should be_empty
        end

        it 'renders the create action' do
          fetch :project_id => project.id, :timeline => {:name => ''}

          response.should render_template('timelines/new', :formats => ["html"], :layout => :base)
        end

        it 'assigns the unsaved timeline instance for the view to access it' do
          fetch :project_id => project.id, :timeline => {:name => ''}

          t = assigns[:timeline]
          t.should be_new_record
        end
      end
    end
  end

  describe 'show.html' do
    def fetch(options = {})
      get "show", options
    end

    it_should_behave_like 'all actions related to an existing timeline'

    describe 'w/ everything set up' do
      let(:project)  { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:timeline) { FactoryGirl.create(:timelines, :project_id => project.id, :name => 'b') }
      let(:other_timelines) {
        [FactoryGirl.create(:timelines, :project_id => project.id, :name => 'c'),
         FactoryGirl.create(:timelines, :project_id => project.id, :name => 'a')]
      }

      become_member_with_view_permissions

      it 'assigns the visible_timelines array' do
        visible_timelines = [timeline] + other_timelines

        fetch :project_id => project.id, :id => timeline.id
        assigns(:visible_timelines).should =~ visible_timelines
      end

      describe 'visible_timelines array' do
        it 'is sorted alphabetically by name' do
          visible_timelines = [timeline] + other_timelines
          visible_timelines = visible_timelines.sort_by(&:name)

          fetch :project_id => project.id, :id => timeline.id
          assigns(:visible_timelines).should == visible_timelines
        end
      end

      it 'renders the show template' do
        fetch :project_id => project.id, :id => timeline.id
        response.should render_template('timelines/show', :formats => ["html"], :layout => :base)
      end
    end
  end

  describe 'edit.html' do
    def fetch(options = {})
      get "edit", options
    end

    it_should_behave_like 'all actions related to an existing timeline'

    describe 'w/ everything set up' do
      become_member_with_edit_permissions

      let(:project)  { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:timeline) { FactoryGirl.create(:timelines, :project_id => project.id, :name => 'b') }

      it 'renders the edit template' do
        fetch :project_id => project.id, :id => timeline.id
        response.should render_template('timelines/edit', :formats => ["html"], :layout => :base)
      end
    end
  end

  describe 'update.html' do
    def fetch(options = {})
      post "update", options
    end

    it_should_behave_like 'all actions related to an existing timeline'

    describe 'w/ everything set up' do
      become_member_with_edit_permissions

      let(:project)  { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:timeline) { FactoryGirl.create(:timelines, :project_id => project.id, :name => 'b') }

      describe 'w/ proper parameters' do
        it 'updates the existing timelines instance' do
          fetch :project_id => project.id, :id => timeline.id, :timeline => {:name => 'bb'}

          timeline.reload
          timeline.name.should == 'bb'
        end

        it 'redirects to show' do
          fetch :project_id => project.id, :id => timeline.id, :timeline => {:name => 'bb'}

          response.should redirect_to(project_timeline_path(project, timeline))
        end

        it 'notifies the user about the successful update' do
          fetch :project_id => project.id, :id => timeline.id, :timeline => {:name => 'bb'}

          flash[:notice].should =~ /success/i
        end
      end

      describe 'w/o proper parameters' do
        it 'does not save the edited timelines instance' do
          fetch :project_id => project.id, :id => timeline.id, :timeline => {:name => ''}

          timeline.reload
          timeline.name.should == 'b'
        end

        it 'renders the edit action' do
          fetch :project_id => project.id, :id => timeline.id, :timeline => {:name => ''}

          response.should render_template('timelines/edit', :formats => ["html"], :layout => :base)
        end

        it 'assigns the unsaved timeline instance for the view to access it' do
          fetch :project_id => project.id, :id => timeline.id, :timeline => {:name => ''}

          t = assigns[:timeline]
          t.should be_changed
        end
      end
    end
  end

  describe 'confirm_destroy.html' do
    def fetch(options = {})
      get "confirm_destroy", options
    end

    it_should_behave_like 'all actions related to an existing timeline'

    describe 'w/ everything set up' do
      become_member_with_delete_permissions

      let(:project)  { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:timeline) { FactoryGirl.create(:timelines, :project_id => project.id, :name => 'b') }

      it 'renders the confirm_destroy action' do
        fetch :project_id => project.id, :id => timeline.id

        response.should render_template('timelines/confirm_destroy', :formats => ["html"], :layout => :base)
      end
    end
  end

  describe 'destroy.html' do
    def fetch(options = {})
      post "destroy", options
    end

    it_should_behave_like 'all actions related to an existing timeline'

    describe 'w/ everything set up' do
      become_member_with_delete_permissions

      let(:project)  { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:timeline) { FactoryGirl.create(:timelines, :project_id => project.id, :name => 'b') }

      it 'deletes the existing timelines instance' do
        fetch :project_id => project.id, :id => timeline.id

        expect { timeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'redirects to index' do
        fetch :project_id => project.id, :id => timeline.id

        response.should redirect_to project_timelines_path project
      end

      it 'notifies the user about the successful deletion' do
        fetch :project_id => project.id, :id => timeline.id

        flash[:notice].should =~ /success/i
      end
    end
  end
end
