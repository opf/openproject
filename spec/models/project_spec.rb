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

require 'spec_helper'
require File.expand_path('../../support/shared/become_member', __FILE__)

describe Project do
  include BecomeMember

  let(:project) { FactoryGirl.build(:project) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }

  describe Project::STATUS_ACTIVE do
    it "equals 1" do
      # spec that STATUS_ACTIVE has the correct value
      Project::STATUS_ACTIVE.should == 1
    end
  end

  describe "#active?" do
    before do
      # stub out the actual value of the constant
      stub_const('Project::STATUS_ACTIVE', 42)
    end

    it "is active when :status equals STATUS_ACTIVE" do
      project = FactoryGirl.create :project, :status => 42
      project.should be_active
    end

    it "is not active when :status doesn't equal STATUS_ACTIVE" do
      project = FactoryGirl.create :project, :status => 99
      project.should_not be_active
    end
  end

  describe "associated_project_candidates" do
    let(:project_type) { FactoryGirl.create(:project_type, :allows_association => true) }

    before do
      FactoryGirl.create(:type_standard)
    end

    it "should not include the project" do
      project.project_type = project_type
      project.save!

      project.associated_project_candidates(admin).should be_empty
    end
  end

  describe "add_planning_element" do
    let(:project) { FactoryGirl.create(:project_with_types) }

    it 'should return a work package' do
      project.add_planning_element.should be_a(PlanningElement)
    end

    it 'the object should be a new record' do
      project.add_planning_element.should be_new_record
    end

    it 'should have the project associated' do
      project.add_planning_element.project.should == project
    end

    it 'should assign the attributes' do
      attributes = { :blubs => double('blubs') }

      new_pe = FactoryGirl.build_stubbed(:planning_element)

      project.planning_elements.should_receive(:build).and_yield(new_pe)

      new_pe.should_receive(:attributes=).with(attributes)

      project.add_planning_element(attributes)
    end
  end

  describe "add_issue" do
    let(:project) { FactoryGirl.create(:project_with_types) }

    it "should return a new issue" do
      project.add_issue.should be_a(Issue)
    end

    it "should not be saved" do
      project.add_issue.should be_new_record
    end

    it "returned issue should have project set to self" do
      project.add_issue.project.should == project
    end

    it "returned issue should have type set to project's first type" do
      project.add_issue.type.should == project.types.first
    end

    it "returned issue should have type set to provided type" do
      specific_type = FactoryGirl.build(:type)
      project.types << specific_type

      project.add_issue(:type => specific_type).type.should == specific_type
    end

    it "should raise an error if the provided type is not one of the project's types" do
      # Load project first so that the new type is not automatically included
      project
      specific_type = FactoryGirl.create(:type)

      expect { project.add_issue(:type => specific_type) }.to raise_error ActiveRecord::RecordNotFound
    end

    it "returned issue should have type set to provided type_id" do
      specific_type = FactoryGirl.build(:type)
      project.types << specific_type

      project.add_issue(:type_id => specific_type.id).type.should == specific_type
    end

    it "should set all the other attributes" do
      attributes = { :blubs => double('blubs') }

      new_issue = FactoryGirl.build_stubbed(:issue)
      new_issue.should_receive(:attributes=).with(attributes)

      Issue.stub!(:new).and_yield(new_issue)

      project.add_issue(attributes)
    end
  end

  describe :find_visible do
    it 'should find the project by id if the user is project member' do
      become_member_with_permissions(project, user, :view_work_packages)

      Project.find_visible(user, project.id).should == project
    end

    it 'should find the project by identifier if the user is project member' do
      become_member_with_permissions(project, user, :view_work_packages)

      Project.find_visible(user, project.identifier).should == project
    end

    it 'should not find the project by identifier if the user is no project member' do
      expect { Project.find_visible(user, project.identifier) }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should not find the project by id if the user is no project member' do
      expect { Project.find_visible(user, project.id) }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
