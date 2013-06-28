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

describe WorkPackagesController do
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


  before do
    User.stub(:current).and_return current_user
  end

  #=======================================================================

  describe 'show.html' do
    let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

    become_admin

    describe 'w/o a valid planning element id' do

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 404 page' do
          get 'show', :id => '1337'

          response.response_code.should === 404
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it 'raises ActiveRecord::RecordNotFound errors' do
          get 'show', :id => '1337'

          response.response_code.should === 404
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      let(:planning_element) { FactoryGirl.create(:planning_element, :project_id => project.id) }

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'show', :id => planning_element.id

          response.response_code.should == 403
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it 'assigns the planning_element' do
          get 'show', :id => planning_element.id
          assigns(:planning_element).should == planning_element
        end

        it 'renders the show builder template' do
          get 'show', :id => planning_element.id
          response.should render_template('work_packages/show', :formats => ["html"], :layout => :base)
        end
      end
    end
  end
end
