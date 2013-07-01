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
      role   = FactoryGirl.create(:role, :permissions => [:view_planning_elements, :view_work_packages])

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

  let(:planning_element) { FactoryGirl.create(:planning_element, :project_id => project.id) }
  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:current_user) { FactoryGirl.create(:user) }

  describe 'show.html' do

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

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'show', :id => planning_element.id

          response.response_code.should == 403
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        before do
          get 'show', :id => planning_element.id
        end

        it 'renders the show builder template' do
          response.should render_template('work_packages/show', :formats => ["html"], :layout => :base)
        end
      end
    end
  end

  describe :work_package do
    describe 'when beeing allowed to see the work_package' do
      become_member_with_view_planning_element_permissions

      it 'should return the work_package' do
        controller.params = { id: planning_element.id }

        controller.work_package.should == planning_element
      end

      it 'should return nil for non existing work_packages' do
        controller.params = { id: 0 }

        controller.work_package.should be_nil
      end
    end

    describe 'when not beeing allowed to see the work_package' do
      it 'should return nil' do
        controller.params = { id: planning_element.id }

        controller.work_package.should be_nil
      end
    end
  end

  describe :project do
    it "should be the work_packages's project" do
      controller.stub!(:work_package).and_return(planning_element)

      controller.project.should == project
    end
  end

  describe :journals do
    it "should be empty" do
      controller.journals.should be_empty
    end
  end

  describe :changesets do
    it "should be empty" do
      controller.changesets.should be_empty
    end
  end

  describe :relations do
    it "should be empty" do
      controller.relations.should be_empty
    end
  end

  describe :ancestors do
    it "should be empty" do
      controller.ancestors.should be_empty
    end
  end

  describe :descendants do
    it "should be empty" do
      controller.descendants.should be_empty
    end
  end

  describe :edit_allowed? do
    it "should be false" do
      controller.edit_allowed?.should be_false
    end
  end

#  describe :time_entry do
#    it "should be a TimeEntry" do
#      controller.time_entry.should be_a(TimeEntry)
#    end
#
#    it "should be a new_record" do
#      controller.time_entry.new_record?.should be_true
#    end
#  end
end
