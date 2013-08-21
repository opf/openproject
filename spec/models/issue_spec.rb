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

describe Issue do
  describe 'Acts as journalized' do
    before(:each) do
      IssueStatus.delete_all
      IssuePriority.delete_all

      @status_resolved ||= FactoryGirl.create(:issue_status, :name => "Resolved", :is_default => false)
      @status_open ||= FactoryGirl.create(:issue_status, :name => "Open", :is_default => true)
      @status_rejected ||= FactoryGirl.create(:issue_status, :name => "Rejected", :is_default => false)

      @priority_low ||= FactoryGirl.create(:priority_low, :is_default => true)
      @priority_high ||= FactoryGirl.create(:priority_high)
      @type ||= FactoryGirl.create(:type_feature)
      @project ||= FactoryGirl.create(:project_with_types)

      @current = FactoryGirl.create(:user, :login => "user1", :mail => "user1@users.com")
      User.stub!(:current).and_return(@current)

      @user2 = FactoryGirl.create(:user, :login => "user2", :mail => "user2@users.com")


      @issue ||= FactoryGirl.create(:issue, :project => @project, :status => @status_open, :type => @type, :author => @current)
    end

    describe 'ignore blank to blank transitions' do
      it 'should not include the "nil to empty string"-transition' do
        @issue.description = nil
        @issue.save!

        @issue.description = ""
        @issue.send(:incremental_journal_changes).should be_empty
      end
    end

    describe 'Acts as journalized recreate initial journal' do
      it 'should not include certain attributes' do
        recreated_journal = @issue.recreate_initial_journal!

        recreated_journal.changed_data.include?('rgt').should == false
        recreated_journal.changed_data.include?('lft').should == false
        recreated_journal.changed_data.include?('lock_version').should == false
        recreated_journal.changed_data.include?('updated_at').should == false
        recreated_journal.changed_data.include?('updated_on').should == false
        recreated_journal.changed_data.include?('id').should == false
        recreated_journal.changed_data.include?('type').should == false
        recreated_journal.changed_data.include?('root_id').should == false
      end

      it 'should not include useless transitions' do
        recreated_journal = @issue.recreate_initial_journal!

        recreated_journal.changed_data.values.each do |change|
          change.first.should_not == change.last
        end
      end

      it 'should not be different from the initially created journal by aaj' do
        # Creating four journals total
        @issue.status = @status_resolved
        @issue.assigned_to = @user2
        @issue.save!
        @issue.reload

        @issue.priority = @priority_high
        @issue.save!
        @issue.reload

        @issue.status = @status_rejected
        @issue.priority = @priority_low
        @issue.estimated_hours = 3
        @issue.save!

        initial_journal = @issue.journals.first
        recreated_journal = @issue.recreate_initial_journal!

        initial_journal.should be_identical(recreated_journal)
      end

      it "should not validate with oddly set estimated_hours" do
        @issue.estimated_hours = "this should not work"
        @issue.should_not be_valid
      end

      it "should validate with sane estimated_hours" do
        @issue.estimated_hours = "13h"
        @issue.should be_valid
      end
    end
  end

end
