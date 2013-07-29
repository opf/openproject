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

# TODO: this spec is for now targeting each WorkPackage subclass
# independently. Once only WorkPackage exist, this can safely be consolidated.
describe WorkPackage do
  let(:project) { FactoryGirl.build(:project_with_types) }
  let(:issue) { FactoryGirl.build(:issue, :project => project, :type => project.types.first) }
  let(:issue2) { FactoryGirl.build(:issue, :project => project, :type => project.types.first) }
  let(:issue3) { FactoryGirl.build(:issue, :project => project, :type => project.types.first) }
  let(:planning_element) { FactoryGirl.build(:planning_element, :project => project) }
  let(:planning_element2) { FactoryGirl.build(:planning_element, :project => project) }
  let(:planning_element3) { FactoryGirl.build(:planning_element, :project => project) }

  [:issue, :planning_element].each do |subclass|

    describe "(#{subclass})" do
      let(:instance) { send(subclass) }
      let(:parent) { send(:"#{subclass}2") }
      let(:parent2) { send(:"#{subclass}3") }

      shared_examples_for "root" do
        it "should set root_id to the id of the #{subclass}" do
          instance.root_id.should == instance.id
        end

        it "should set lft to 1" do
          instance.lft.should == 1
        end

        it "should set rgt to 2" do
          instance.rgt.should == 2
        end
      end

      shared_examples_for "first child" do
        it "should set root_id to the id of the parent #{subclass}" do
          instance.root_id.should == parent.id
        end

        it "should set lft to 2" do
          instance.lft.should == 2
        end

        it "should set rgt to 3" do
          instance.rgt.should == 3
        end
      end

      describe "creating a new instance without a parent" do

        before do
          instance.save!
        end

        it_should_behave_like "root"
      end

      describe "creating a new instance with a parent" do

        before do
          parent.save!
          instance.parent_issue_id = parent.id

          instance.save!
        end

        it_should_behave_like "first child"
      end

      describe "an existant instance receives a parent" do

        before do
          parent.save!
          instance.save!
          instance.parent_issue_id = parent.id
          instance.save!
        end

        it_should_behave_like "first child"
      end

      describe "an existant instance becomes a root" do

        before do
          parent.save!
          instance.parent_issue_id = parent.id
          instance.save!
          instance.parent_issue_id = nil
          instance.save!
        end

        it_should_behave_like "root"
      end

      describe "an existant instance receives a new parent (new tree)" do

        before do
          parent.save!
          parent2.save!
          instance.parent_issue_id = parent2.id
          instance.save!

          instance.parent_issue_id = parent.id
          instance.save!
        end

        it_should_behave_like "first child"
      end

      describe "an existant instance receives a new parent (same tree)" do

        before do
          parent.save!
          parent2.save!
          instance.parent_issue_id = parent2.id
          instance.save!

          instance.parent_issue_id = parent.id
          instance.save!
        end

        it_should_behave_like "first child"
      end

      describe "an existant instance with children receives a new parent (itself)" do
        let(:child) { send(:"#{subclass}3") }

        before do
          parent.save!
          instance.parent_issue_id = parent.id
          instance.save!
          child.parent_issue_id = instance.id
          child.save!

          instance.parent_issue_id = nil
          instance.save!
          child.reload
        end

        it "the child should have the root_id of the #{subclass}" do
          child.root_id.should == instance.id
        end

        it "the child should have a lft of 2" do
          child.lft.should == 2
        end

        it "the child should have a rgt of 3" do
          child.rgt.should == 3
        end
      end
    end
  end
end
