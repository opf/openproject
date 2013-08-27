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
describe WorkPackage, "#reschedule_after" do
  let(:project) { FactoryGirl.build(:project_with_types) }
  let(:issue) { FactoryGirl.create(:issue, :project => project, :type => project.types.first) }
  let(:issue2) { FactoryGirl.create(:issue, :project => project, :type => project.types.first) }
  let(:issue3) { FactoryGirl.create(:issue, :project => project, :type => project.types.first) }
  let(:planning_element) { FactoryGirl.create(:planning_element, :project => project) }
  let(:planning_element2) { FactoryGirl.create(:planning_element, :project => project) }
  let(:planning_element3) { FactoryGirl.create(:planning_element, :project => project) }

  [:issue, :planning_element].each do |subclass|

    describe "for a #{subclass}" do
      let(:instance) { send(subclass) }
      let(:child) do
        child = send(:"#{subclass}2")
        child.parent_id = instance.id

        child
      end
      let(:grandchild) do
        gchild = send(:"#{subclass}3")
        gchild.parent_id = child.id

        gchild
      end

      describe "for a single node having start and due date" do
        before do
          instance.start_date = Date.today
          instance.due_date = Date.today + 7.days

          instance.reschedule_after(Date.today + 3.days)
        end

        it "should set the start_date to the provided date" do
          instance.start_date.should == Date.today + 3.days
        end

        it "should set the set the due date plus the duration" do
          instance.due_date.should == Date.today + 10.days
        end
      end

      describe "for a single node having neither start nor due date" do
        before do
          instance.start_date = nil
          instance.due_date = nil

          instance.reschedule_after(Date.today + 3.days)
        end

        it "should set the start_date to the provided date" do
          instance.start_date.should == Date.today + 3.days
        end

        it "should set the set the due date plus the duration" do
          instance.due_date.should == Date.today + 3.days
        end
      end

      describe "for a single node having only a due date" do
        before do
          instance.start_date = nil
          instance.due_date = Date.today + 7.days

          instance.reschedule_after(Date.today + 3.days)
        end

        it "should set the start_date to the provided date" do
          instance.start_date.should == Date.today + 3.days
        end

        it "should set the set the due date plus the duration" do
          instance.due_date.should == Date.today + 3.days
        end
      end

      describe "with a child" do
        before do
          child.start_date = Date.today
          child.due_date = Date.today + 7.days
          child.save!
          instance.reload

          instance.reschedule_after(Date.today + 3.days)
        end

        it "should set the start_date to the provided date" do
          instance.reload
          instance.start_date.should == Date.today + 3.days
        end

        it "should set the set the due date to the provided date plus the child's duration" do
          instance.reload
          instance.due_date.should == Date.today + 10.days
        end

        it "should set the child's start date to the provided date" do
          child.reload
          child.start_date.should == Date.today + 3.days
        end

        it "should set the set child's due date to the provided date plus the child's duration" do
          child.reload
          child.due_date.should == Date.today + 10.days
        end
      end

      describe "with a child
                while the new date is set to be between the child's start and due date" do
        before do
          child.start_date = Date.today + 1.day
          child.due_date = Date.today + 7.days

          child.save!
          instance.reload

          instance.start_date = Date.today
          instance.due_date = Date.today + 7.days

          instance.reschedule_after(Date.today + 3.days)
        end

        it "should set the start_date to the provided date" do
          instance.reload
          instance.start_date.should == Date.today + 3.days
        end

        it "should set the set the due date to the provided date plus the child's duration" do
          instance.reload
          instance.due_date.should == Date.today + 9.days
        end

        it "should set the child's start date to the provided date" do
          child.reload
          child.start_date.should == Date.today + 3.days
        end

        it "should set the set child's due date to the provided date plus the child's duration" do
          child.reload
          child.due_date.should == Date.today + 9.days
        end
      end

      describe "with child and grandchild" do

        before do
          child.save
          grandchild.start_date = Date.today
          grandchild.due_date = Date.today + 7.days

          grandchild.save!
          instance.reload

          instance.reschedule_after(Date.today + 3.days)
        end

        it "should set the start_date to the provided date" do
          instance.reload
          instance.start_date.should == Date.today + 3.days
        end

        it "should set the set the due date to the provided date plus the child's duration" do
          instance.reload
          instance.due_date.should == Date.today + 10.days
        end

        it "should set the child's start date to the provided date" do
          child.reload
          child.start_date.should == Date.today + 3.days
        end

        it "should set the set child's due date to the provided date plus the grandchild's duration" do
          child.reload
          child.due_date.should == Date.today + 10.days
        end

        it "should set the grandchild's start date to the provided date" do
          grandchild.reload
          grandchild.start_date.should == Date.today + 3.days
        end

        it "should set the set grandchild's due date to the provided date plus the grandchild's duration" do
          grandchild.reload
          grandchild.due_date.should == Date.today + 10.days
        end
      end
    end
  end
end
