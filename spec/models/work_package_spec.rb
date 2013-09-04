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

  describe :custom_fields do
    let (:custom_field) { FactoryGirl.create(:work_package_custom_field,
                                             name: 'Database',
                                             field_format: 'list',
                                             possible_values: ['MySQL', 'PostgreSQL', 'Oracle'],
                                             is_required: true) }

    before do
      def self.change_custom_field_value(value)
        work_package.custom_field_values = { custom_field.id => value } unless value.nil?
        work_package.save
      end
    end

    context "required custom field exists" do
      before do
        project.work_package_custom_fields << custom_field
        work_package.save
      end

      subject { work_package.available_custom_fields }

      it { should include(custom_field) }

      describe "invalid custom field values" do
        context "short error message" do
          shared_examples_for "custom field with invalid value" do
            let(:modified_work_package_subject) { "Should not be saved" }

            before do
              work_package.subject = modified_work_package_subject

              change_custom_field_value(custom_field_value)
            end

            describe "error message" do
              before { work_package.save }

              subject { work_package.errors[:custom_values] }

              it { should include(I18n.translate('activerecord.errors.messages.invalid')) }
            end

            describe "work package attribute update" do
              subject { work_package.save }

              it { should be_false }
            end
          end

          context "no value given" do
            let(:custom_field_value) { nil }

            it_behaves_like "custom field with invalid value"
          end

          context "empty value given" do
            let(:custom_field_value) { '' }

            it_behaves_like "custom field with invalid value"
          end

          context "invalid value given" do
            let(:custom_field_value) { 'SQLServer' }

            it_behaves_like "custom field with invalid value"
          end
        end

        context "full error message" do
          before { change_custom_field_value('SQLServer') }

          subject { work_package.errors.full_messages.first }

          it { should eq("Database is not included in the list") }
        end
      end

      describe "valid value given" do
        before { change_custom_field_value('PostgreSQL') }

        context :errors do
          subject { work_package.errors[:custom_values] }

          it { should be_empty }
        end

        context :save do
          before do
            work_package.save!
            work_package.reload
          end

          subject { work_package.custom_value_for(custom_field.id).value }

          it { should eq('PostgreSQL') }
        end

        describe "value change" do
          before do
            change_custom_field_value('PostgreSQL')
            @initial_custom_value = work_package.custom_value_for(custom_field).id
            change_custom_field_value('MySQL')

            work_package.reload
          end

          subject { work_package.custom_value_for(custom_field).id }

          it { should eq(@initial_custom_value) }
        end
      end
    end

    describe "work package type change" do
      let (:custom_field_2) { FactoryGirl.create(:work_package_custom_field) }
      let(:type_feature) { FactoryGirl.create(:type_feature,
                                              custom_fields: [custom_field_2]) }

      context "with initial type" do
        before do
          custom_field
          project.types << type_feature

          change_custom_field_value('PostgreSQL')
          work_package.reload

          work_package.type = type_feature
          work_package.save!
        end

        subject { work_package.custom_value_for(custom_field).value }

        it { should eq('PostgreSQL') }
      end

      context "w/o initial type" do
        let(:project_without_custom_fields) { FactoryGirl.build_stubbed(:project) }
        let(:work_package_without_type) { FactoryGirl.build_stubbed(:work_package,
                                                                    project: project_without_custom_fields) }

        subject { work_package_without_type.custom_field_values }

        it { should be_empty }

        context "assign type" do
          before { work_package_without_type.type = type_feature }

          it { should_not be_empty }
        end
      end

      describe "assign type id first" do
        let(:attribute_hash) { ActiveSupport::OrderedHash.new }

        before do
          attribute_hash['custom_field_values'] = { custom_field.id => 'MySQL' }
          attribute_hash['type_id'] = type_feature
        end

        subject do
          wp = WorkPackage.new.tap do |i|
            i.force_attributes = { :project => project }
          end
          wp.attributes = attribute_hash

          wp.custom_value_for(custom_field.id).value
        end

        it { should eq('MySQL') }
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
