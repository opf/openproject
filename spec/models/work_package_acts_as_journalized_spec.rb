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
  let(:type) { FactoryGirl.create :type }
  let(:project) { FactoryGirl.create :project,
                                     types: [type] }
  let(:status) { FactoryGirl.create :default_issue_status }
  let(:priority) { FactoryGirl.create :priority }
  let(:work_package) { FactoryGirl.create(:planning_element,
                                          :project_id => project.id,
                                          :type => type,
                                          :priority => priority) }
  let(:current_user) { FactoryGirl.create(:user) }

  before do
    User.stub(:current).and_return current_user

    work_package
  end

  context "on work package creation" do
    it { Journal.all.count.should eq(1) }

    it "has a journal entry" do
      Journal.first.journaled.should eq(work_package)
    end
  end

  context "nothing is changed" do
    before { work_package.save! }

    it { Journal.all.count.should eq(1) }
  end

  context "on work package change" do
    let(:parent_work_package) { FactoryGirl.create(:planning_element,
                                                   :project_id => project.id,
                                                   :type => type,
                                                   :priority => priority) }
    let(:type_2) { FactoryGirl.create :type }
    let(:status_2) { FactoryGirl.create :issue_status }
    let(:priority_2) { FactoryGirl.create :priority }

    before do
      work_package.subject = "changed"
      work_package.description = "changed"
      work_package.type = type_2
      work_package.status = status_2
      work_package.priority = priority_2
      work_package.start_date = Date.new(2013, 1, 24)
      work_package.due_date = Date.new(2013, 1, 31)
      work_package.estimated_hours = 40.0
      work_package.assigned_to = User.current
      work_package.responsible = User.current
      work_package.parent = parent_work_package

      work_package.save!
    end

    context "last created journal" do
      subject { work_package.journals.last.changed_data }

      it "contains all changes" do
        [:subject, :description, :type_id, :status_id, :priority_id,
         :start_date, :due_date, :estimated_hours, :assigned_to_id,
         :responsible_id, :parent_id].each do |a|
          subject.should have_key(a), "Missing change for #{a.to_s}"
        end
      end
    end
  end

  context "attachments" do
    let(:attachment) { FactoryGirl.create :attachment,
                                          container: work_package }
    let(:attachment_id) { "attachments_#{attachment.id}".to_sym }

    before do
      attachment
    end

    context "new attachment" do
      subject { work_package.journals.last.changed_data }

      it { should have_key attachment_id }

      it { subject[attachment_id].should eq([nil, attachment.filename]) }
    end

    context "attachment modified" do
      before do
        @old_filename = attachment.filename

        attachment.filename = "changed"
        attachment.save!
      end

      subject { work_package.journals.last.changed_data }

      it { should have_key attachment_id }

      it { subject[attachment_id].should eq([@old_filename, attachment.filename]) }
    end
  end
end
