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
  let(:stub_version) { FactoryGirl.build_stubbed(:version) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project) }
  let(:issue) { FactoryGirl.create(:issue) }
  let(:planning_element) { FactoryGirl.create(:planning_element).reload }
  let(:user) { FactoryGirl.create(:user) }

  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:status) { FactoryGirl.create(:issue_status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:work_package) { WorkPackage.new.tap do |w|
                         w.force_attributes = { project_id: project.id,
                           type_id: type.id,
                           author_id: user.id,
                           status_id: status.id,
                           priority: priority,
                           subject: 'test_create',
                           description: 'WorkPackage#create',
                           estimated_hours: '1:30' }
                       end }

  describe "create" do
    describe :save do
      subject { work_package.save }

      it { should be_true }
    end

    describe :estimated_hours do
      before do
        work_package.save!
        work_package.reload
      end

      subject { work_package.estimated_hours }

      it { should eq(1.5) }
    end

    describe "minimal" do
      let(:work_package_minimal) { WorkPackage.new.tap do |w|
                                     w.force_attributes = { project_id: project.id,
                                       type_id: type.id,
                                       author_id: user.id,
                                       status_id: status.id,
                                       priority: priority,
                                       subject: 'test_create' }
                                 end }

      context :save do
        subject { work_package_minimal.save }

        it { should be_true }
      end

      context :description do
        before do
          work_package_minimal.save!
          work_package_minimal.reload
        end

        subject { work_package_minimal.description }

        it { should be_nil }
      end
    end
  end

  describe :type do
    context "disabled type" do
      describe "allows work package update" do
        before do
          work_package.save!

          project.types.delete work_package.type

          work_package.reload
          work_package.subject = "New subject"
        end

        subject { work_package.save }

        it { should be_true }
      end

      describe "must not be set on work package" do
        before do
          project.types.delete work_package.type
        end

        context :save do
          subject { work_package.save }

          it { should be_false }
        end

        context :errors do
          before { work_package.save }

          subject { work_package.errors[:type_id] }

          it { should_not be_empty }
        end
      end
    end
  end

  describe :category do
    let(:user_2) { FactoryGirl.create(:user, member_in_project: project) }
    let(:category) { FactoryGirl.create(:issue_category,
                                        project: project,
                                        assigned_to: user_2) }

    before do
      work_package.force_attributes = { category_id: category.id }
      work_package.save!
    end

    subject { work_package.assigned_to }

    it { should eq(category.assigned_to) }
  end

  describe :assignable_users do
    let(:user) { FactoryGirl.build_stubbed(:user) }

    context "single user" do
      before { stub_work_package.project.stub(:assignable_users).and_return([user]) }

      subject { stub_work_package.assignable_users }

      it 'should return all users the project deems to be assignable' do
        should include(user)
      end
    end

    context "multiple users" do
      let(:user_2) { FactoryGirl.build_stubbed(:user) }

      before { stub_work_package.project.stub(:assignable_users).and_return([user, user_2]) }

      subject { stub_work_package.assignable_users.uniq }

      it { should eq(stub_work_package.assignable_users) }
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

  describe :assignable_versions do
    let(:work_package) { FactoryGirl.build(:work_package,
                                           project: project,
                                           fixed_version: version) }
    let(:version_open) { FactoryGirl.create(:version,
                                            status: 'open',
                                            project: project) }
    let(:version_locked) { FactoryGirl.create(:version,
                                              status: 'locked',
                                              project: project) }
    let(:version_closed) { FactoryGirl.create(:version,
                                              status: 'closed',
                                              project: project) }

    describe :assignment do
      context "open version" do
        let(:version) { version_open }

        subject { work_package.assignable_versions.collect(&:status).uniq }

        it { should include('open') }
      end

      shared_examples_for "invalid version" do
        before { work_package.save }

        subject { work_package.errors[:fixed_version_id] }

        it { should_not be_empty }
      end

      context "closed version" do
        let(:version) { version_closed }

        it_behaves_like "invalid version"
      end

      context "locked version" do
        let(:version) { version_locked }

        it_behaves_like "invalid version"
      end

      context "open version" do
        let(:version) { version_open }

        before { work_package.save }

        it { should be_true }
      end
    end

    describe "work package update" do
      let(:status_closed) { FactoryGirl.create(:issue_status,
                                               is_closed: true) }
      let(:status_open) { FactoryGirl.create(:issue_status,
                                             is_closed: false) }

      context "closed version" do
        let(:version) { FactoryGirl.create(:version,
                                           status: 'open',
                                           project: project) }

        before do
          version_open

          work_package.status = status_closed
          work_package.save!
        end

        shared_context "in closed version" do
          before do
            version.status = 'closed'
            version.save!
          end
        end

        context "attribute update" do
          include_context "in closed version"

          before { work_package.subject = "Subject changed" }

          subject { work_package.save }

          it { should be_true }
        end

        context "status changed" do
          shared_context "in locked version" do
            before do
              version.status = 'locked'
              version.save!
            end
          end

          shared_examples_for "save with open version" do
            before do 
              work_package.status = status_open
              work_package.fixed_version = version_open
            end

            subject { work_package.save }

            it { should be_true }
          end

          context "in closed version" do
            include_context "in closed version"

            before do 
              work_package.status = status_open
              work_package.save
            end

            subject { work_package.errors[:base] }

            it { should_not be_empty }
          end

          context "from closed version" do
            include_context "in closed version"

            it_behaves_like "save with open version"
          end

          context "from locked version" do
            include_context "in locked version"

            it_behaves_like "save with open version"
          end
        end
      end
    end
  end

  describe :move do
    let(:work_package) { FactoryGirl.create(:work_package,
                                            project: project,
                                            type: type) }
    let(:target_project) { FactoryGirl.create(:project) }

    shared_examples_for "moved work package" do
      subject { work_package.project }

      it { should eq(target_project) }
    end

    describe :time_entries do
      let(:time_entry_1) { FactoryGirl.create(:time_entry,
                                              project: project,
                                              work_package: work_package) }
      let(:time_entry_2) { FactoryGirl.create(:time_entry,
                                              project: project,
                                              work_package: work_package) }

      before do
        time_entry_1
        time_entry_2

        work_package.reload
        work_package.move_to_project(target_project)

        time_entry_1.reload
        time_entry_2.reload
      end

      context "time entry 1" do
        subject { work_package.time_entries } 

        it { should include(time_entry_1) }
      end

      context "time entry 2" do
        subject { work_package.time_entries } 

        it { should include(time_entry_2) }
      end

      it_behaves_like "moved work package"
    end

    describe :category do
      let(:category) { FactoryGirl.create(:issue_category,
                                          project: project) }

      before do
        work_package.category = category
        work_package.save!

        work_package.reload
      end

      context "with same category" do
        let(:target_category) { FactoryGirl.create(:issue_category,
                                                   name: category.name,
                                                   project: target_project) }

        before do
          target_category

          work_package.move_to_project(target_project)
        end

        describe "category moved" do
          subject { work_package.category_id }

          it { should eq(target_category.id) }
        end
        
        it_behaves_like "moved work package"
      end

      context "w/o target category" do
        before { work_package.move_to_project(target_project) }

        describe "category discarded" do
          subject { work_package.category_id }

          it { should be_nil }
        end

        it_behaves_like "moved work package"
      end
    end

    describe :version do
      let(:sharing) { 'none' }
      let(:version) { FactoryGirl.create(:version,
                                         status: 'open',
                                         project: project,
                                         sharing: sharing) }
      let(:work_package) { FactoryGirl.create(:work_package,
                                              fixed_version: version,
                                              project: project) }

      before { work_package.move_to_project(target_project) }

      it_behaves_like "moved work package"

      context "unshared version" do
        subject { work_package.fixed_version }

        it { should be_nil }
      end

      context "system wide shared version" do
        let(:sharing) { 'system' }

        subject { work_package.fixed_version }

        it { should eq(version) }
      end

      context "move work package in project hierarchy" do
        let(:target_project) { FactoryGirl.create(:project,
                                                  parent: project) }

        context "unshared version" do
          subject { work_package.fixed_version }

          it { should be_nil }
        end

        context "shared version" do
          let(:sharing) { 'tree' }

          subject { work_package.fixed_version }

          it { should eq(version) }
        end
      end
    end

    describe :type do
      let(:target_type) { FactoryGirl.create(:type) }
      let(:target_project) { FactoryGirl.create(:project,
                                                types: [ target_type ]) }

      subject { work_package.move_to_project(target_project) }

      it { should be_false }
    end
  end

  describe :destroy do
    let(:time_entry_1) { FactoryGirl.create(:time_entry,
                                            project: project,
                                            work_package: work_package) }
    let(:time_entry_2) { FactoryGirl.create(:time_entry,
                                            project: project,
                                            work_package: work_package) }

    before do
      time_entry_1
      time_entry_2

      work_package.destroy
    end

    context "work package" do
      subject { WorkPackage.find_by_id(work_package.id) }

      it { should be_nil }
    end

    context "time entries" do
      subject { TimeEntry.find_by_work_package_id(work_package.id) }

      it { should be_nil }
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
                                        :project_id => project.id)
      work_package.new_statuses_allowed_to(user).should =~ [statuses[0], statuses[1]]
    end

    it "should respect workflows w/ author and w/o assignee on work packages" do
      workflows
      work_package = WorkPackage.create(:type => type,
                                        :status => status,
                                        :priority => priority,
                                        :project_id => project.id,
                                        :author => user)
      work_package.new_statuses_allowed_to(user).should =~ [statuses[0], statuses[1], statuses[2]]
    end

    it "should respect workflows w/o author and w/ assignee on work packages" do
      workflows
      work_package = WorkPackage.create(:type => type,
                                        :status => status,
                                        :subject => "test",
                                        :priority => priority,
                                        :project_id => project.id,
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
                                        :project_id => project.id,
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
    [:issue, :planning_element].each do |subclass|

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
    [:issue, :planning_element].each do |subclass|

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
end
