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

describe Project do
  let(:project) { FactoryGirl.build(:project) }
  let(:admin) { FactoryGirl.create(:admin) }

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

    it "should not include the project" do
      project.project_type = project_type
      project.save!

      project.associated_project_candidates(admin).should be_empty
    end
  end

  describe "add_planning_element" do
    let(:project) { FactoryGirl.create(:project_with_trackers) }

    it 'should return a work package' do
      project.add_planning_element.should be_a(PlanningElement)
    end

    it 'the object should be a new record' do
      project.add_planning_element.should be_new_record
    end

    it 'should have the project associated' do
      project.add_planning_element.project.should == project
    end
  end

  describe "add_issue" do
    let(:project) { FactoryGirl.create(:project_with_trackers) }

    it "should return a new issue" do
      project.add_issue.should be_a(Issue)
    end

    it "should not be saved" do
      project.add_issue.should be_new_record
    end

    it "returned issue should have project set to self" do
      project.add_issue.project.should == project
    end

    it "returned issue should have tracker set to project's first tracker" do
      project.add_issue.tracker.should == project.trackers.first
    end

    it "returned issue should have tracker set to provided tracker" do
      specific_tracker = FactoryGirl.build(:tracker)
      project.trackers << specific_tracker

      project.add_issue(:tracker => specific_tracker).tracker.should == specific_tracker
    end

    it "should raise an error if the provided tracker is not one of the project's trackers" do
      # Load project first so that the new tracker is not automatically included
      project
      specific_tracker = FactoryGirl.create(:tracker)

      expect { project.add_issue(:tracker => specific_tracker) }.to raise_error ActiveRecord::RecordNotFound
    end

    it "returned issue should have tracker set to provided tracker_id" do
      specific_tracker = FactoryGirl.build(:tracker)
      project.trackers << specific_tracker

      project.add_issue(:tracker_id => specific_tracker.id).tracker.should == specific_tracker
    end

    it "should call safe_attributes to override all the other attributes" do
      # TODO: replace once StrongParameters is in place
      attributes = { :blubs => double('blubs') }

      new_issue = FactoryGirl.build_stubbed(:issue)
      new_issue.should_receive(:safe_attributes=).with(attributes)

      Issue.stub!(:new).and_yield(new_issue)

      project.add_issue(attributes)
    end
  end
end
