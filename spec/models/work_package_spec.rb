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
  let(:user) { FactoryGirl.create(:user) }

  describe :assignable_users do
    it 'should return all users the project deems to be assignable' do
      stub_work_package.project.stub(:assignable_users).and_return([stub_user])

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

      stub_work_package.project.stub(:shared_versions).and_return(versions)
    end

    it "should return all the project's shared versions" do
      stub_shared_versions(stub_version)

      stub_work_package.assignable_versions.should == [stub_version]
    end

    it "should return the current fixed_version" do
      stub_shared_versions

      stub_work_package.stub(:fixed_version_id_was).and_return(5)
      Version.stub(:find_by_id).with(5).and_return(stub_version)

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

    it "should copy over watchers" do
      source.watchers.build(:user => stub_user)

      sink.copy_from(source)

      sink.should have(1).watchers
      sink.watchers[0].user.should == stub_user
    end
  end

  describe :new_statuses_allowed_to do

    let(:role) { FactoryGirl.create(:role) }
    let(:type) { FactoryGirl.create(:type) }
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    let(:statuses) { (1..5).map{ |i| FactoryGirl.create(:issue_status)}}
    let(:priority) { FactoryGirl.create :priority, is_default: true }
    let(:status) { statuses[0] }
    let(:project) do
      FactoryGirl.create(:project, :types => [type]).tap { |p| p.add_member(user, role).save }
    end
    let(:workflow_a) { FactoryGirl.create(:workflow, :role_id => role.id,
                                                     :type_id => type.id,
                                                     :old_status_id => statuses[0].id,
                                                     :new_status_id => statuses[1].id,
                                                     :author => false,
                                                     :assignee => false)}
    let(:workflow_b) { FactoryGirl.create(:workflow, :role_id => role.id,
                                                     :type_id => type.id,
                                                     :old_status_id => statuses[0].id,
                                                     :new_status_id => statuses[2].id,
                                                     :author => true,
                                                     :assignee => false)}
    let(:workflow_c) { FactoryGirl.create(:workflow, :role_id => role.id,
                                                     :type_id => type.id,
                                                     :old_status_id => statuses[0].id,
                                                     :new_status_id => statuses[3].id,
                                                     :author => false,
                                                     :assignee => true)}
    let(:workflow_d) { FactoryGirl.create(:workflow, :role_id => role.id,
                                                     :type_id => type.id,
                                                     :old_status_id => statuses[0].id,
                                                     :new_status_id => statuses[4].id,
                                                     :author => true,
                                                     :assignee => true)}
    let(:workflows) { [workflow_a, workflow_b, workflow_c, workflow_d] }

    it "should respect workflows w/o author and w/o assignee" do
      workflows
      status.new_statuses_allowed_to([role], type, false, false).should =~ [statuses[1]]
      status.find_new_statuses_allowed_to([role], type, false, false).should =~ [statuses[1]]
    end

    it "should respect workflows w/ author and w/o assignee" do
      workflows
      status.new_statuses_allowed_to([role], type, true, false).should =~ [statuses[1], statuses[2]]
      status.find_new_statuses_allowed_to([role], type, true, false).should =~ [statuses[1], statuses[2]]
    end

    it "should respect workflows w/o author and w/ assignee" do
      workflows
      status.new_statuses_allowed_to([role], type, false, true).should =~ [statuses[1], statuses[3]]
      status.find_new_statuses_allowed_to([role], type, false, true).should =~ [statuses[1], statuses[3]]
    end

    it "should respect workflows w/ author and w/ assignee" do
      workflows
      status.new_statuses_allowed_to([role], type, true, true).should =~ [statuses[1], statuses[2], statuses[3], statuses[4]]
      status.find_new_statuses_allowed_to([role], type, true, true).should =~ [statuses[1], statuses[2], statuses[3], statuses[4]]
    end

    it "should respect workflows w/o author and w/o assignee on work packages" do
      workflows
      work_package = WorkPackage.create(:type => type,
                                        :status => status,
                                        :priority => priority,
                                        :project => project)
      work_package.new_statuses_allowed_to(user).should =~ [statuses[0], statuses[1]]
    end

    it "should respect workflows w/ author and w/o assignee on work packages" do
      workflows
      work_package = WorkPackage.create(:type => type,
                                        :status => status,
                                        :priority => priority,
                                        :project => project,
                                        :author => user)
      work_package.new_statuses_allowed_to(user).should =~ [statuses[0], statuses[1], statuses[2]]
    end

    it "should respect workflows w/o author and w/ assignee on work packages" do
      workflows
      work_package = WorkPackage.create(:type => type,
                                        :status => status,
                                        :subject => "test",
                                        :priority => priority,
                                        :project => project,
                                        :assigned_to => user,
                                        :author => other_user)
      work_package.new_statuses_allowed_to(user).should =~ [statuses[0], statuses[1], statuses[3]]
    end

    it "should respect workflows w/ author and w/ assignee on work packages" do
      workflows
      work_package = WorkPackage.create(:type => type,
                                        :status => status,
                                        :subject => "test",
                                        :priority => priority,
                                        :project => project,
                                        :author => user,
                                        :assigned_to => user)
      work_package.new_statuses_allowed_to(user).should =~ [statuses[0], statuses[1], statuses[2], statuses[3], statuses[4]]
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

  describe :update_by! do
    #TODO remove once only WP exists
    [:issue].each do |subclass|

      describe "for #{subclass}" do
        let(:instance) { send(subclass) }

        it "should return true" do
          instance.update_by!(user, {}).should be_true
        end

        it "should set the values" do
          instance.update_by!(user, { :subject => "New subject" })

          instance.subject.should == "New subject"
        end

        it "should create a journal with the journal's 'notes' attribute set to the supplied" do
          instance.update_by!(user, { :notes => "blubs" })

          instance.journals.last.notes.should == "blubs"
        end

        it "should attach an attachment" do
          raw_attachments = [double('attachment')]
          attachment = FactoryGirl.build(:attachment)

          Attachment.should_receive(:attach_files)
                    .with(instance, raw_attachments)
                    .and_return(attachment)

          instance.update_by!(user, { :attachments => raw_attachments })
        end

        it "should only attach the attachment when saving was successful" do
          raw_attachments = [double('attachment')]

          Attachment.should_not_receive(:attach_files)

          instance.update_by!(user, { :subject => "", :attachments => raw_attachments })
        end

        it "should add a time entry" do
          activity = FactoryGirl.create(:time_entry_activity)

          instance.update_by!(user, { :time_entry => { "hours" => "5",
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

          instance.update_by!(user, { :subject => '',
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

          instance.update_by!(user, :time_entry => time_attributes)

          instance.should have(0).time_entries
        end
      end
    end
  end

  describe "#allowed_target_projects_on_move" do
    let(:admin_user) { FactoryGirl.create :admin }
    let(:valid_user) { FactoryGirl.create :user }
    let(:project) { FactoryGirl.create :project }

    context "admin user" do
      before do
        User.stub(:current).and_return admin_user
        project
      end

      subject { WorkPackage.allowed_target_projects_on_move.count }

      it "sees all active projects" do
        should eq Project.active.count
      end
    end

    context "non admin user" do
      before do
        User.stub(:current).and_return valid_user

        role = FactoryGirl.create :role, permissions: [:move_work_packages]

        FactoryGirl.create(:member, user: valid_user, project: project, roles: [role])
      end

      subject { WorkPackage.allowed_target_projects_on_move.count }

      it "sees all active projects" do
        should eq Project.active.count
      end
    end
  end

  describe :duration do
    #TODO remove once only WP exists
    [:issue].each do |subclass|

      describe "for #{subclass}" do
        let(:instance) { send(subclass) }

        describe "w/ today as start date
                  w/ tomorrow as due date" do
          before do
            instance.start_date = Date.today
            instance.due_date = Date.today + 1.day
          end

          it "should have a duration of two" do
            instance.duration.should == 2
          end
        end

        describe "w/ today as start date
                  w/ today as due date" do
          before do
            instance.start_date = Date.today
            instance.due_date = Date.today
          end

          it "should have a duration of one" do
            instance.duration.should == 1
          end
        end

        describe "w/ today as start date
                  w/o a due date" do
          before do
            instance.start_date = Date.today
            instance.due_date = nil
          end

          it "should have a duration of one" do
            instance.duration.should == 1
          end
        end

        describe "w/o a start date
                  w today as due date" do
          before do
            instance.start_date = nil
            instance.due_date = Date.today
          end

          it "should have a duration of one" do
            instance.duration.should == 1
          end
        end

      end
    end
  end

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
      User.stub(:current).and_return(@current)

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
