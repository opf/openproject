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
  describe :relation do
    let(:closed_state) { FactoryGirl.create(:issue_status, is_closed: true) }
    let(:original) { FactoryGirl.create(:work_package) }
    let(:dup_1) { FactoryGirl.create(:work_package,
                                     project: original.project) }
    let(:dup_2) { FactoryGirl.create(:work_package,
                                     project: original.project) }
    let(:relation_org_dup_1) { FactoryGirl.create(:issue_relation,
                                                  issue_from: dup_1,
                                                  issue_to: original,
                                                  relation_type: IssueRelation::TYPE_DUPLICATES) }
    let(:relation_dup_1_dup_2) { FactoryGirl.create(:issue_relation,
                                                    issue_from: dup_2,
                                                    issue_to: dup_1,
                                                    relation_type: IssueRelation::TYPE_DUPLICATES) }
    # circular dependency
    let(:relation_dup_2_org) { FactoryGirl.create(:issue_relation,
                                                  issue_from: dup_2,
                                                  issue_to: original,
                                                  relation_type: IssueRelation::TYPE_DUPLICATES) }

    before do
      relation_org_dup_1
      relation_dup_1_dup_2
      relation_dup_2_org
    end

    shared_examples_for "work package closed" do
      before { work_package.reload }

      subject { work_package.closed? }

      it { should be_true }
    end

    describe "duplicates are closed" do
      before do
        original.status = closed_state
        original.save!
      end

      context "first duplicate closed" do
        let(:work_package) { dup_1 }

        it_behaves_like "work package closed"
      end

      context "second duplicate closed" do
        let(:work_package) { dup_2 }

        it_behaves_like "work package closed"
      end
    end

    describe "duplicated is not closed" do
      before do
        dup_1.status = closed_state
        dup_1.save!

        original.reload
      end

      subject { original.closed? }

      it { should be_false }
    end
  end
end
