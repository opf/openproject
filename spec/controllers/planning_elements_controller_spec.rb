#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../spec_helper', __FILE__)

describe PlanningElementsController do
  # ===========================================================
  # Helpers
  def self.become_admin
    let(:current_user) { FactoryGirl.create(:admin) }
  end

  def self.become_non_member(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        current_user.memberships.select {|m| m.project_id == p.id}.each(&:destroy)
      end
    end
  end

  def self.become_member_with_view_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:view_planning_elements])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        member = FactoryGirl.build(:member, :user => current_user, :project => p)
        member.roles = [role]
        member.save!
      end
    end
  end

  def self.become_member_with_edit_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:edit_planning_elements])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        member = FactoryGirl.build(:member, :user => current_user, :project => p)
        member.roles = [role]
        member.save!
      end
    end
  end

  def self.become_member_with_delete_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, :permissions => [:delete_planning_elements])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        member = FactoryGirl.build(:member, :user => current_user, :project => project)
        member.roles = [role]
        member.save!
      end
    end
  end

  before do
    User.stub(:current).and_return current_user
  end

  # ===========================================================
  # UI tests

  describe 'index.html' do
    describe 'w/o a given project' do
      become_admin

      it 'renders a 404 Not Found page' do
        get 'index'

        response.response_code.should == 404
      end
    end

    describe 'w/ an unknown project' do
      become_admin

      it 'renders a 404 Not Found page' do
        get 'index', :project_id => '4711'

        response.response_code.should == 404
      end
    end

    describe 'w/ a known project' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'index', :project_id => project.identifier

          response.response_code.should == 403
        end
      end

      describe 'w/ the current user having view_planning_elements permissions' do
        become_member_with_view_planning_element_permissions

        describe 'w/o any planning elements within the project' do
          it 'assigns an empty planning_elements array' do
            get 'index', :project_id => project.identifier
            assigns(:planning_elements).should == []
          end

          it 'renders the index builder template' do
            get 'index', :project_id => project.identifier
            response.should render_template('planning_elements/index', :formats => ["html"], :layout => :base)
          end
        end

        describe 'w/ 3 planning elements within the project' do
          before do
            @created_planning_elements = [
              FactoryGirl.create(:planning_element, :project_id => project.id),
              FactoryGirl.create(:planning_element, :project_id => project.id),
              FactoryGirl.create(:planning_element, :project_id => project.id)
            ]
          end

          it 'assigns a planning_elements array containing all three elements' do
            get 'index', :project_id => project.identifier
            assigns(:planning_elements).should =~ @created_planning_elements
          end

          it 'assigns a planning_elements array containing all except the deleted elements' do
            destroyed = @created_planning_elements.first.destroy
            get 'index', :project_id => project.identifier
            assigns(:planning_elements).include?(destroyed).should be_false
          end

          it 'renders the index builder template' do
            get 'index', :project_id => project.identifier
            response.should render_template('planning_elements/index', :formats => ["html"], :layout => :base)
          end
        end
      end
    end
  end

  describe 'show.html' do
    become_admin

    describe 'w/o a valid planning element id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => '4711'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'show', :project_id => '4711', :id => '1337'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'show', :project_id => project.id, :id => '1337'

            response.response_code.should === 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_view_planning_element_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            lambda do
              get 'show', :project_id => project.id, :id => '1337'
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:planning_element) { FactoryGirl.create(:planning_element, :project_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => planning_element.id

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'show', :project_id => project.id, :id => '1337'

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_view_planning_element_permissions

          it 'assigns the planning_element' do
            get 'show', :project_id => project.id, :id => planning_element.id
            assigns(:planning_element).should == planning_element
          end

          it 'renders the show builder template' do
            get 'show', :project_id => project.id, :id => planning_element.id
            response.should render_template('planning_elements/show', :formats => ["html"], :layout => :base)
          end
        end
      end
    end
  end

  describe 'confirm_destroy.html' do
    become_admin

    describe 'w/o a valid planning element id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'confirm_destroy', :id => '4711'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'confirm_destroy', :project_id => '4711', :id => '1337'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'confirm_destroy', :project_id => project.id, :id => '1337'

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_delete_planning_element_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            lambda do
              get 'confirm_destroy', :project_id => project.id, :id => '1337'
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid planning element id' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:planning_element) { FactoryGirl.create(:planning_element, :project_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'confirm_destroy', :id => planning_element.id

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'confirm_destroy', :project_id => project.id, :id => planning_element.id

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_delete_planning_element_permissions

          it 'assigns the planning_element' do
            get 'confirm_destroy', :project_id => project.id, :id => planning_element.id

            assigns(:planning_element).should == planning_element
          end

          it 'renders the confirm_destroy view' do
            get 'confirm_destroy', :project_id => project.id, :id => planning_element.id

            response.should render_template('planning_elements/confirm_destroy', :formats => ["html"], :layout => :base)
          end
        end
      end
    end
  end

  describe 'destroy.html' do
    become_admin

    describe 'w/o a valid planning element id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', :id => '4711'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', :project_id => '4711', :id => '1337'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'destroy', :project_id => project.id, :id => '1337'

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_delete_planning_element_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            lambda do
              get 'destroy', :project_id => project.id, :id => '1337'
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid planning element id' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:planning_element) { FactoryGirl.create(:planning_element, :project_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', :id => planning_element.id

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'destroy', :project_id => project.id, :id => planning_element.id

            response.response_code.should == 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_delete_planning_element_permissions

          it 'assigns the planning_element' do
            get 'destroy', :project_id => project.id, :id => planning_element.id

            assigns(:planning_element).should == planning_element
          end

          it 'redirects to index and adds a notice to the flash' do
            get 'destroy', :project_id => project.id, :id => planning_element.id

            response.should redirect_to(project_planning_elements_path(project))
            flash[:notice].should be_present
          end

          it 'deletes the record' do
            get 'destroy', :project_id => project.id, :id => planning_element.id
            lambda do
              planning_element.reload
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end
end
