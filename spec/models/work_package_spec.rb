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

describe WorkPackage do
  let(:stub_work_package) { FactoryGirl.build_stubbed(:work_package) }
  let(:stub_user) { FactoryGirl.build_stubbed(:user) }
  let(:stub_version) { FactoryGirl.build_stubbed(:version) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project) }
  let(:issue) { FactoryGirl.create(:issue) }
  let(:planning_element) { FactoryGirl.create(:planning_element).reload }
  let(:user) { FactoryGirl.create(:user) }

  describe :assignable_users do
    it 'should return all users the project deems to be assignable' do
      stub_work_package.project.stub!(:assignable_users).and_return([stub_user])

      stub_work_package.assignable_users.should include(stub_user)
    end
  end

  describe :assignable_versions do
    def stub_shared_versions(v = nil)
      versions = v ? [v] : []

      # open seems to be defined on the array's singleton class
      # as such it seems not possible to stub it
      # achieving the same here
      versions.define_singleton_method :open do
        self
      end

      stub_work_package.project.stub!(:shared_versions).and_return(versions)
    end

    it "should return all the project's shared versions" do
      stub_shared_versions(stub_version)

      stub_work_package.assignable_versions.should == [stub_version]
    end

    it "should return the current fixed_version" do
      stub_shared_versions

      stub_work_package.stub!(:fixed_version_id_was).and_return(5)
      Version.stub!(:find_by_id).with(5).and_return(stub_version)

      stub_work_package.assignable_versions.should == [stub_version]
    end
  end

  describe :copy_from do
    let(:source) { FactoryGirl.build(:work_package) }
    let(:sink) { FactoryGirl.build(:work_package) }

    it "should copy project" do
      source.project_id = 1

      sink.copy_from(source)

      sink.project_id.should == source.project_id
    end

    it "should not copy project if explicitly excluded" do
      source.project_id = 1
      orig_project_id = sink.project_id

      sink.copy_from(source, :exclude => [:project_id])

      sink.project_id.should == orig_project_id
    end
  end

  describe :new_statuses_allowed_to do

    it "should work as it did in issue tests" do

      Workflow.delete_all

      Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 1, :new_status_id => 2, :author => false, :assignee => false)
      Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 1, :new_status_id => 3, :author => true, :assignee => false)
      Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 1, :new_status_id => 4, :author => false, :assignee => true)
      Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 1, :new_status_id => 5, :author => true, :assignee => true)
      status = IssueStatus.find(1)
      role = Role.find(1)
      type = Type.find(1)

      assert_equal [2], status.new_statuses_allowed_to([role], type, false, false).map(&:id)
      assert_equal [2], status.find_new_statuses_allowed_to([role], type, false, false).map(&:id)

      assert_equal [2, 3], status.new_statuses_allowed_to([role], type, true, false).map(&:id)
      assert_equal [2, 3], status.find_new_statuses_allowed_to([role], type, true, false).map(&:id)

      assert_equal [2, 4], status.new_statuses_allowed_to([role], type, false, true).map(&:id)
      assert_equal [2, 4], status.find_new_statuses_allowed_to([role], type, false, true).map(&:id)

      assert_equal [2, 3, 4, 5], status.new_statuses_allowed_to([role], type, true, true).map(&:id)
      assert_equal [2, 3, 4, 5], status.find_new_statuses_allowed_to([role], type, true, true).map(&:id)
    end

    it "should work as it did in issue status tests" do

      Workflow.delete_all

      Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 1, :new_status_id => 2, :author => false, :assignee => false)
      Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 1, :new_status_id => 3, :author => true, :assignee => false)
      Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 1, :new_status_id => 4, :author => false, :assignee => true)
      Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 1, :new_status_id => 5, :author => true, :assignee => true)
      status = IssueStatus.find(1)
      role = Role.find(1)
      type = Type.find(1)
      user = User.find(2)

      work_package = WorkPackage.generate!(:type => type, :status => status, :project_id => 1)
      assert_equal [1, 2], work_package.new_statuses_allowed_to(user).map(&:id)

      work_package = WorkPackage.generate!(:type => type, :status => status, :project_id => 1, :author => user)
      assert_equal [1, 2, 3], work_package.new_statuses_allowed_to(user).map(&:id)

      work_package = WorkPackage.generate!(:type => type, :status => status, :project_id => 1, :assigned_to => user)
      assert_equal [1, 2, 4], work_package.new_statuses_allowed_to(user).map(&:id)

      work_package = WorkPackage.generate!(:type => type, :status => status, :project_id => 1, :author => user, :assigned_to => user)
      assert_equal [1, 2, 3, 4, 5], work_package.new_statuses_allowed_to(user).map(&:id)
    end

  end

  describe :add_time_entry do
    it "should return a new time entry" do
      stub_work_package.add_time_entry.should be_a TimeEntry
    end

    it "should already have the project assigned" do
      stub_work_package.project = stub_project

      stub_work_package.add_time_entry.project.should == stub_project
    end

    it "should already have the work_package assigned" do
      stub_work_package.add_time_entry.work_package.should == stub_work_package
    end

    it "should return an usaved entry" do
      stub_work_package.add_time_entry.should be_new_record
    end
  end

  describe :update_with do
    #TODO remove once only WP exists
    [:issue, :planning_element].each do |subclass|

      describe "for #{subclass}" do
        let(:instance) { send(subclass) }

        it "should return true" do
          instance.update_by(user, {}).should be_true
        end

        it "should set the values" do
          instance.update_by(user, { :subject => "New subject" })

          instance.subject.should == "New subject"
        end

        it "should create a journal with the journal's 'notes' attribute set to the supplied" do
          instance.update_by(user, { :notes => "blubs" })

          instance.journals.last.notes.should == "blubs"
        end

        it "should attach an attachment" do
          raw_attachments = [double('attachment')]
          attachment = FactoryGirl.build(:attachment)

          Attachment.should_receive(:attach_files)
                    .with(instance, raw_attachments)
                    .and_return(attachment)

          instance.update_by(user, { :attachments => raw_attachments })
        end

        it "should only attach the attachment when saving was successful" do
          raw_attachments = [double('attachment')]
          attachment = FactoryGirl.build(:attachment)

          Attachment.should_not_receive(:attach_files)

          instance.update_by(user, { :subject => "", :attachments => raw_attachments })
        end

        it "should add a time entry" do
          activity = FactoryGirl.create(:time_entry_activity)

          instance.update_by(user, { :time_entry => { "hours" => "5",
                                                      "activity_id" => activity.id.to_s,
                                                      "comments" => "blubs" } } )

          instance.should have(1).time_entries

          entry = instance.time_entries.first

          entry.should be_persisted
          entry.work_package.should == instance
          entry.user.should == user
          entry.project.should == instance.project
          entry.spent_on.should == Date.today
        end

        it "should not persist the time entry if the #{subclass}'s update fails" do
          activity = FactoryGirl.create(:time_entry_activity)

          instance.update_by(user, { :subject => '',
                                     :time_entry => { "hours" => "5",
                                                      "activity_id" => activity.id.to_s,
                                                      "comments" => "blubs" } } )

          instance.should have(1).time_entries

          entry = instance.time_entries.first

          entry.should_not be_persisted
        end

        it "should not add a time entry if the time entry attributes are empty" do
          time_attributes = { "hours" => "",
                              "activity_id" => "",
                              "comments" => "" }

          instance.update_by(user, :time_entry => time_attributes)

          instance.should have(0).time_entries
        end
      end
    end
  end
end
