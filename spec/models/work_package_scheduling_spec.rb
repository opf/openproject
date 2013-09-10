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
  describe :overdue do
    let(:work_package) { FactoryGirl.create(:work_package,
                                            due_date: due_date) }

    shared_examples_for "overdue" do
      subject { work_package.overdue? }

      it { should be_true }
    end

    shared_examples_for "on time" do
      subject { work_package.overdue? }

      it { should be_false }
    end

    context "one day ago" do
      let(:due_date) { 1.day.ago.to_date }

      it_behaves_like "overdue"
    end

    context "today" do
      let(:due_date) { Date.today.to_date }

      it_behaves_like "on time"
    end

    context "next day" do
      let(:due_date) { 1.day.from_now.to_date }

      it_behaves_like "on time"
    end

    context "no due date" do
      let(:due_date) { nil }

      it_behaves_like "on time"
    end

    context "status closed" do
      let(:due_date) { 1.day.ago.to_date }
      let(:status) { FactoryGirl.create(:issue_status,
                                        is_closed: true) }

      before { work_package.status = status }

      it_behaves_like "on time"
    end
  end
end
