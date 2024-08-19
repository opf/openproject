#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::UpdateAncestorsService, type: :model do
  shared_association_default(:author, factory_name: :user) { create(:user) }
  shared_association_default(:project_with_types) { create(:project_with_types) }
  shared_association_default(:priority) { create(:priority) }
  shared_association_default(:open_status, factory_name: :status) { create(:status, name: "Open", default_done_ratio: 0) }
  shared_let(:closed_status) { create(:closed_status, name: "Closed", default_done_ratio: 100) }
  shared_let(:rejected_status) { create(:rejected_status, default_done_ratio: 20) }
  shared_let(:user) { create(:user) }

  # In order to have dependent values computed, this leverages
  # the SetAttributesService to mimic how attributes are set
  # on work packages prior to the UpdateAncestorsService being
  # executed.
  def set_attributes_on(work_package, attributes)
    WorkPackages::SetAttributesService
      .new(user:,
           model: work_package,
           contract_class: WorkPackages::UpdateContract)
      .call(attributes)
  end

  def call_update_ancestors_service(work_package)
    changed_attributes = work_package.changes.keys.map(&:to_sym)
    described_class.new(user:, work_package:)
                    .call(changed_attributes)
  end

  describe "work, remaining work, and % complete propagation" do
    context 'when using the "status-based" progress calculation mode',
            with_settings: { work_package_done_ratio: "status" } do
      context "with both parent and children having work set" do
        shared_let_work_packages(<<~TABLE)
          hierarchy | status | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
          parent    | Open   |  10h |    15h |            10h |              15h |         0% |           0%
            child   | Open   |   5h |        |             5h |                  |         0% |
        TABLE

        context "when changing child status to a status with a default % complete ratio" do
          %i[status status_id].each do |field|
            context "with the #{field} field" do
              it "recomputes child remaining work and updates ancestors total % complete accordingly" do
                value =
                  case field
                  when :status then closed_status
                  when :status_id then closed_status.id
                  end
                set_attributes_on(child, field => value)
                call_update_ancestors_service(child)

                expect_work_packages([parent, child], <<~TABLE)
                  | subject | status | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete |
                  | parent  | Open   |  10h |    15h |            10h |              10h |         0% |          33% |
                  |   child | Closed |   5h |        |             0h |                  |       100% |              |
                TABLE
              end
            end
          end
        end

        context "when changing child status to a status excluded from totals calculation" do
          before do
            set_attributes_on(child, status: rejected_status)
            call_update_ancestors_service(child)
          end

          it "still recomputes child remaining work and updates ancestors total % complete excluding it" do
            expect_work_packages([parent, child], <<~TABLE)
              | subject | status   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete |
              | parent  | Open     |  10h |    10h |            10h |              10h |         0% |           0% |
              |   child | Rejected |   5h |        |             4h |                  |        20% |              |
            TABLE
          end
        end
      end

      context "with parent having nothing set, and 2 children having values set (bug #54179)" do
        shared_let_work_packages(<<~TABLE)
          hierarchy | status | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
          parent    | Open   |      |    15h |                |              10h |         0% |          33%
            child1  | Open   |  10h |        |            10h |                  |         0% |
            child2  | Closed |   5h |        |             0h |                  |       100% |
        TABLE

        context "when changing children to all have 100% complete" do
          before do
            set_attributes_on(child1, status: closed_status)
            call_update_ancestors_service(child1)
          end

          it "sets parent total % complete to 100% and its total remaining work to 0h" do
            expect_work_packages(table_work_packages, <<~TABLE)
              hierarchy | status | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
              parent    | Open   |      |    15h |                |               0h |         0% |         100%
                child1  | Closed |  10h |        |             0h |                  |       100% |
                child2  | Closed |   5h |        |             0h |                  |       100% |
            TABLE
          end
        end
      end
    end

    context "for the new ancestor chain" do
      shared_examples "attributes of parent having children" do
        it "is a success" do
          expect(subject)
          .to be_success
        end

        it "updates one work package - the parent" do
          expect(subject.dependent_results.map(&:result))
          .to contain_exactly(parent)
        end

        it "has the expected total % complete" do
          expect(subject.dependent_results.first.result.derived_done_ratio)
          .to eq expected_total_p_complete
        end

        it "has the expected total work" do
          expect(subject.dependent_results.first.result.derived_estimated_hours)
          .to eq expected_total_work
        end

        it "has the expected total remaining work" do
          expect(subject.dependent_results.first.result.derived_remaining_hours)
            .to eq expected_total_remaining_work
        end
      end

      shared_context "when work is changed" do
        subject do
          # On work-based mode, changing estimated_hours
          # entails done_ratio also changing when going
          # through the SetAttributesService
          described_class
            .new(user:,
                 work_package: child1)
            .call(%i(estimated_hours done_ratio))
        end
      end

      shared_context "when remaining work is changed" do
        subject do
          # On work-based mode, changing remaining work
          # entails % complete also changing when going
          # through the SetAttributesService
          described_class
            .new(user:,
                 work_package: child1)
            .call(%i(remaining_hours done_ratio))
        end
      end

      context "without any work or % complete being set" do
        shared_let_work_packages(<<~TABLE)
          hierarchy   | work | remaining work | % complete
          parent      |      |                |
            child1    |      |                |
            child2    |      |                |
            child3    |      |                |
        TABLE

        for_each_context "when work is changed",
                         "when remaining work is changed" do
          it "is a success" do
            expect(subject)
              .to be_success
          end

          it "does not update the parent" do
            expect(subject.dependent_results)
              .to be_empty
          end
        end
      end

      context "with all children tasks having work and remaining work set" do
        shared_let_work_packages(<<~TABLE)
          hierarchy   | work | remaining work | % complete
          parent      |      |                |
            child1    |  10h |             0h |       100%
            child2    |  10h |             0h |       100%
            child3    |  10h |            10h |         0%
        TABLE

        for_each_context "when work is changed",
                         "when remaining work is changed" do
          it_behaves_like "attributes of parent having children" do
            let(:expected_total_work) do
              30.0
            end
            let(:expected_total_remaining_work) do
              10.0
            end
            let(:expected_total_p_complete) do
              67
            end
          end
        end
      end

      context "with all children tasks having work and remaining work set (second example)" do
        shared_let_work_packages(<<~TABLE)
          hierarchy   | work | remaining work | % complete
          parent      |      |                |
            child1    |  10h |           2.5h |        75%
            child2    |  10h |           2.5h |        75%
            child3    |  10h |            10h |         0%
        TABLE

        for_each_context "when work is changed",
                         "when remaining work is changed" do
          it_behaves_like "attributes of parent having children" do
            let(:expected_total_work) do
              30.0
            end
            let(:expected_total_remaining_work) do
              15.0
            end
            let(:expected_total_p_complete) do
              50
            end
          end
        end
      end

      context "with all children tasks having work set to positive value, and having remaining work set to 0h" do
        shared_let_work_packages(<<~TABLE)
          hierarchy   | work | remaining work | % complete
          parent      |      |                |
            child1    |  10h |             0h |       100%
            child2    |   2h |             0h |       100%
            child3    |   3h |             0h |       100%
        TABLE

        for_each_context "when work is changed",
                         "when remaining work is changed" do
          it_behaves_like "attributes of parent having children" do
            let(:expected_total_work) do
              15.0
            end
            let(:expected_total_remaining_work) do
              0.0
            end
            let(:expected_total_p_complete) do
              100
            end
          end
        end
      end

      context "with some children tasks having work and remaining work set" do
        shared_let_work_packages(<<~TABLE)
          hierarchy   | work | remaining work | % complete
          parent      |      |                |
            child1    |  10h |           2.5h |        75%
            child2    |      |                |
            child3    |      |                |
        TABLE

        for_each_context "when work is changed",
                         "when remaining work is changed" do
          it_behaves_like "attributes of parent having children" do
            let(:expected_total_work) do
              10.0
            end
            let(:expected_total_remaining_work) do
              2.5
            end
            let(:expected_total_p_complete) do
              75
            end
          end
        end
      end

      context "with the parent having work and % complete set " \
              "and some children tasks having work and % complete set" do
        shared_let_work_packages(<<~TABLE)
          hierarchy   | work | remaining work | % complete
          parent      |  10h |             5h |        50%
            child1    |  10h |           2.5h |        75%
            child2    |      |                |
            child3    |      |                |
        TABLE

        for_each_context "when work is changed",
                         "when remaining work is changed" do
          it_behaves_like "attributes of parent having children" do
            # Parent's work and remaining work are taken into account
            let(:expected_total_work) do
              20.0
            end
            let(:expected_total_remaining_work) do
              7.5
            end
            let(:expected_total_p_complete) do
              63
            end
          end
        end
      end

      context "with the parent having work and % complete set " \
              "and no children tasks having work or % complete set" do
        shared_let_work_packages(<<~TABLE)
          hierarchy   | work | remaining work | % complete
          parent      |  10h |             5h |        50%
            child1    |      |                |
            child2    |      |                |
            child3    |      |                |
        TABLE

        for_each_context "when work is changed",
                         "when remaining work is changed" do
          it_behaves_like "attributes of parent having children" do
            # Parent's work and remaining work become the total values
            let(:expected_total_work) do
              10.0
            end
            let(:expected_total_remaining_work) do
              5.0
            end
            let(:expected_total_p_complete) do
              50
            end
          end
        end
      end
    end

    context "for the previous ancestors" do
      shared_let_work_packages(<<~TABLE)
        hierarchy        | work | remaining work | % complete
        grandparent      |   3h |           1.5h |        50%
          parent         |   3h |             0h |       100%
            work package |      |                |
            sibling      |   7h |           3.5h |        50%
      TABLE

      subject do
        work_package.parent = nil
        work_package.save!

        described_class
          .new(user:,
               work_package:)
          .call(%i(parent))
      end

      it "is successful" do
        expect(subject)
          .to be_success
      end

      it "updates the totals of the ancestors" do
        subject
        expect_work_packages([grandparent, parent, sibling, work_package], <<~TABLE)
          hierarchy        | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          grandparent      |   3h |           1.5h |        50% |    13h |               5h |          62%
            parent         |   3h |             0h |       100% |    10h |             3.5h |          65%
              sibling      |   7h |           3.5h |        50% |        |                  |
          work package     |      |                |            |        |                  |
        TABLE
      end

      it "returns the former ancestors in the dependent results" do
        expect(subject.dependent_results.map(&:result))
          .to contain_exactly(parent, grandparent)
      end
    end

    context "for new ancestors" do
      shared_context "if setting the parent" do
        subject do
          work_package.parent = parent
          work_package.save!

          described_class
            .new(user:,
                 work_package:)
            .call(%i(parent))
        end
      end

      shared_context "if setting the parent_id" do
        subject do
          work_package.parent_id = parent.id
          work_package.save!

          described_class
            .new(user:,
                 work_package:)
            .call(%i(parent_id))
        end
      end

      shared_let_work_packages(<<~TABLE)
        hierarchy    | work | remaining work | % complete
        grandparent  |      |                |
          parent     |   3h |           1.5h |        50%
        work package |   7h |           3.5h |        50%
      TABLE

      for_each_context "if setting the parent",
                       "if setting the parent_id" do
        it "is successful" do
          expect(subject)
            .to be_success
        end

        it "returns the new ancestors in the dependent results" do
          expect(subject.dependent_results.map(&:result))
            .to contain_exactly(parent, grandparent)
        end

        it "updates the totals of the ancestors" do
          subject
          expect_work_packages([grandparent, parent, work_package], <<~TABLE)
            hierarchy        | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            grandparent      |      |                |            |    10h |               5h |          50%
              parent         |   3h |           1.5h |        50% |    10h |               5h |          50%
                work package |   7h |           3.5h |        50% |        |                  |
          TABLE
        end
      end
    end

    context "with old and new parent having a common ancestor" do
      # work_package's parent will change from old parent to new parent, same grandparent
      shared_let_work_packages(<<~TABLE)
        hierarchy        | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
        grandparent      |      |                |            |     7h |             3.5h |          50%
          old parent     |      |                |            |     7h |             3.5h |          50%
            work package |   7h |           3.5h |        50% |        |                  |
          new parent     |      |                |            |        |                  |
      TABLE

      subject do
        # In this test case, done_ratio, derived_estimated_hours, and
        # derived_remaining_hours would not inherently change on grandparent
        # if work package keeps the same progress values.
        #
        # To verify that grandparent can be properly updated in this scenario,
        # work and remaining work are also changed on the work package to force
        # grandparent totals to be updated.
        set_attributes_on(work_package,
                          parent: new_parent,
                          estimated_hours: 10,
                          remaining_hours: 2)
        work_package.save!

        described_class
          .new(user:,
               work_package:)
          .call(%i(parent))
      end

      it "is successful" do
        expect(subject)
          .to be_success
      end

      it "updates the totals of the new parent and the former parent" do
        subject
        expect_work_packages([grandparent, old_parent, new_parent, work_package], <<~TABLE)
          hierarchy        | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          grandparent      |      |                |            |    10h |               2h |          80%
            old parent     |      |                |            |        |                  |
            new parent     |      |                |            |    10h |               2h |          80%
              work package |  10h |             2h |        80% |        |                  |
        TABLE
      end

      it "returns both the former and new ancestors in the dependent results without duplicates" do
        expect(subject.dependent_results.map(&:result))
          .to contain_exactly(new_parent, grandparent, old_parent)
      end
    end
  end

  describe "work propagation" do
    context "when setting work of a work package having children without any work value" do
      shared_let(:parent) { create(:work_package, subject: "parent") }
      shared_let(:child) { create(:work_package, subject: "child", parent:) }

      before do
        parent.estimated_hours = 2.0
      end

      subject(:call_result) do
        described_class.new(user:, work_package: parent)
                       .call(%i(estimated_hours))
      end

      it "sets its total work to the same value" do
        expect { call_result }
          .to change(parent, :derived_estimated_hours).from(nil).to(2.0)
        expect(call_result).to be_success
        expect(call_result.dependent_results).to be_empty
      end
    end

    context "for the new ancestors chain" do
      context "with parent having no work set" do
        let_work_packages(<<~TABLE)
          hierarchy | work |
          parent    |      |
            child1  |   0h |
            child2  |      |
            child3  | 2.5h |
        TABLE

        subject(:call_result) do
          described_class.new(user:, work_package: child1)
                         .call(%i(estimated_hours))
        end

        it "sets parent total work to the sum of children work" do
          expect(call_result).to be_success
          updated_work_packages = call_result.dependent_results.map(&:result)
          expect_work_packages(updated_work_packages, <<~TABLE)
            subject | total work |
            parent  |       2.5h |
          TABLE
        end
      end

      context "with parent having work set" do
        let_work_packages(<<~TABLE)
          hierarchy |  work |
          parent    | 5.25h |
            child1  |    0h |
            child2  |       |
            child3  |  2.5h |
        TABLE

        subject(:call_result) do
          described_class.new(user:, work_package: child1)
                         .call(%i(estimated_hours))
        end

        it "sets parent total work to the sum of itself and children work" do
          expect(call_result).to be_success
          updated_work_packages = call_result.dependent_results.map(&:result)
          expect_work_packages(updated_work_packages, <<~TABLE)
            subject | total work |
            parent  |      7.75h |
          TABLE
        end
      end

      context "with parent and children having no work" do
        let_work_packages(<<~TABLE)
          hierarchy | work |
          parent    |      |
            child1  |      |
            child2  |      |
        TABLE

        subject(:call_result) do
          described_class.new(user:, work_package: child1)
                         .call(%i(estimated_hours))
        end

        it "does not update the parent total work" do
          expect(call_result).to be_success
          expect(call_result.dependent_results).to be_empty
          expect_work_packages([parent.reload], <<~TABLE)
            subject | total work |
            parent  |            |
          TABLE
        end
      end
    end
  end

  describe "remaining work propagation" do
    shared_let(:parent) { create(:work_package, subject: "parent") }
    shared_let(:child) { create(:work_package, subject: "child", parent:) }

    context "when setting remaining work of a work package having children without any remaining work value" do
      before do
        parent.remaining_hours = 2.0
      end

      subject(:call_result) do
        described_class.new(user:, work_package: parent)
                       .call(%i(remaining_hours))
      end

      it "sets its total remaining work to the same value" do
        expect { call_result }
          .to change(parent, :derived_remaining_hours).from(nil).to(2.0)
        expect(call_result).to be_success
        expect(call_result.dependent_results).to be_empty
      end
    end

    context "for the new ancestors chain" do
      context "with parent having no remaining work set" do
        let_work_packages(<<~TABLE)
          hierarchy | remaining work |
          parent    |                |
            child1  |             0h |
            child2  |                |
            child3  |           2.5h |
        TABLE

        subject(:call_result) do
          described_class.new(user:, work_package: child1)
                         .call(%i(remaining_hours))
        end

        it "sets parent total remaining work to the sum of children remaining work" do
          expect(call_result).to be_success
          updated_work_packages = call_result.dependent_results.map(&:result)
          expect_work_packages(updated_work_packages, <<~TABLE)
            subject | total remaining work
            parent  |                 2.5h
          TABLE
        end
      end

      context "with parent having remaining work set" do
        let_work_packages(<<~TABLE)
          hierarchy | remaining work |
          parent    |          5.25h |
            child1  |             0h |
            child2  |                |
            child3  |           2.5h |
        TABLE

        subject(:call_result) do
          described_class.new(user:, work_package: child1)
                         .call(%i(remaining_hours))
        end

        it "sets parent total remaining work to the sum of itself and children remaining work" do
          expect(call_result).to be_success
          updated_work_packages = call_result.dependent_results.map(&:result)
          expect_work_packages(updated_work_packages, <<~TABLE)
            subject | total remaining work
            parent  |                7.75h
          TABLE
        end
      end

      context "with parent and children having no remaining work" do
        let_work_packages(<<~TABLE)
          hierarchy | remaining work |
          parent    |                |
            child1  |                |
            child2  |                |
        TABLE

        subject(:call_result) do
          described_class.new(user:, work_package: child1)
                         .call(%i(remaining_hours))
        end

        it "does not update the parent total remaining work" do
          expect(call_result).to be_success
          expect(call_result.dependent_results).to be_empty
          expect_work_packages([parent.reload], <<~TABLE)
            subject | total remaining work
            parent  |
          TABLE
        end
      end
    end
  end

  describe "% complete propagation" do
    shared_let(:parent) { create(:work_package, subject: "parent") }

    context "given child with work, when remaining work being set on parent" do
      let_work_packages(<<~TABLE)
        hierarchy | work | total work | remaining work | total remaining work
        parent    |      |        10h |             7h |
          child1  |  10h |            |                |
      TABLE

      subject(:call_result) do
        described_class.new(user:, work_package: parent)
                        .call(%i(remaining_hours))
      end

      it "sets parent total remaining work and updates total % complete accordingly" do
        expect(call_result).to be_success
        updated_work_packages = call_result.all_results
        expect_work_packages(updated_work_packages, <<~TABLE)
          subject | total remaining work | total % complete
          parent  |                   7h |              30%
        TABLE
      end
    end

    context "given child with remaining work, when work being set on parent" do
      let_work_packages(<<~TABLE)
        hierarchy | work | total work | remaining work | total remaining work
        parent    |  10h |            |                |                   7h
          child1  |      |            |             7h |
      TABLE

      subject(:call_result) do
        described_class.new(user:, work_package: parent)
                        .call(%i(estimated_hours))
      end

      it "sets parent total work and updates total % complete accordingly" do
        expect(call_result).to be_success
        updated_work_packages = call_result.all_results
        expect_work_packages(updated_work_packages, <<~TABLE)
          subject | total work | total % complete
          parent  |        10h |              30%
        TABLE
      end
    end

    context "given child becomes excluded from totals calculation because of its status changed to rejected" do
      shared_let_work_packages(<<~TABLE)
        hierarchy | status | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
        parent    | Open   |  10h |    12h |             1h |               8h |        90% |          33%
          child   | Open   |   2h |        |             7h |                  |        29% |
      TABLE

      subject(:call_result) do
        set_attributes_on(child, status: rejected_status)
        call_update_ancestors_service(child)
      end

      it "computes parent totals excluding the child from calculations accordingly" do
        expect(call_result).to be_success
        updated_work_packages = call_result.all_results
        expect_work_packages(updated_work_packages, <<~TABLE)
          hierarchy | status   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
          parent    | Open     |  10h |    10h |             1h |               1h |        90% |          90%
            child   | Rejected |   2h |        |             7h |                  |        29% |
        TABLE
      end
    end

    context "given child is no longer excluded from totals calculation because of its status changed from rejected" do
      shared_let_work_packages(<<~TABLE)
        hierarchy | status   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
        parent    | Open     |  10h |    10h |             1h |               1h |        90% |          90%
          child   | Rejected |   2h |        |             7h |                  |        29% |
      TABLE

      subject(:call_result) do
        set_attributes_on(child, status: open_status)
        call_update_ancestors_service(child)
      end

      it "computes parent totals excluding the child from calculations accordingly" do
        expect(call_result).to be_success
        updated_work_packages = call_result.all_results
        expect_work_packages(updated_work_packages, <<~TABLE)
          hierarchy | status | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
          parent    | Open   |  10h |    12h |             1h |               8h |        90% |          33%
            child   | Open   |   2h |        |             7h |                  |        29% |
        TABLE
      end
    end
  end

  describe "ignore_non_working_days propagation" do
    shared_let(:grandgrandparent) do
      create(:work_package,
             subject: "grandgrandparent")
    end
    shared_let(:grandparent) do
      create(:work_package,
             subject: "grandparent",
             parent: grandgrandparent)
    end
    shared_let(:parent) do
      create(:work_package,
             subject: "parent",
             parent: grandparent)
    end
    shared_let(:sibling) do
      create(:work_package,
             subject: "sibling",
             parent:)
    end
    shared_let(:work_package) do
      create(:work_package)
    end

    subject do
      work_package.parent = new_parent
      work_package.save!

      described_class
        .new(user:,
             work_package:)
        .call(%i(parent))
    end

    let(:new_parent) { parent }

    context "for the previous ancestors (parent removed)" do
      let(:new_parent) { nil }

      before do
        work_package.parent = parent
        work_package.save

        [grandgrandparent, grandparent, parent, work_package].each do |wp|
          wp.update_column(:ignore_non_working_days, true)
        end

        [sibling].each do |wp|
          wp.update_column(:ignore_non_working_days, false)
        end
      end

      it "is successful" do
        expect(subject)
          .to be_success
      end

      it "returns the former ancestors in the dependent results" do
        expect(subject.dependent_results.map(&:result))
          .to contain_exactly(parent, grandparent, grandgrandparent)
      end

      it "sets the ignore_non_working_days property of the former ancestor chain to the value of the " \
         "only remaining child (former sibling)" do
        subject

        expect(parent.reload.ignore_non_working_days)
          .to be_falsey

        expect(grandparent.reload.ignore_non_working_days)
          .to be_falsey

        expect(grandgrandparent.reload.ignore_non_working_days)
          .to be_falsey

        expect(sibling.reload.ignore_non_working_days)
          .to be_falsey
      end
    end

    context "for the new ancestors where the grandparent is on manual scheduling" do
      before do
        [grandgrandparent, work_package].each do |wp|
          wp.update_column(:ignore_non_working_days, true)
        end

        [grandparent, parent, sibling].each do |wp|
          wp.update_column(:ignore_non_working_days, false)
        end

        [grandparent].each do |wp|
          wp.update_column(:schedule_manually, true)
        end
      end

      it "is successful" do
        expect(subject)
          .to be_success
      end

      it "returns the former ancestors in the dependent results" do
        expect(subject.dependent_results.map(&:result))
          .to contain_exactly(parent)
      end

      it "sets the ignore_non_working_days property of the new ancestors" do
        subject

        expect(parent.reload.ignore_non_working_days)
          .to be_truthy

        expect(grandparent.reload.ignore_non_working_days)
          .to be_falsey

        expect(grandgrandparent.reload.ignore_non_working_days)
          .to be_truthy

        expect(sibling.reload.ignore_non_working_days)
          .to be_falsey
      end
    end

    context "for the new ancestors where the parent is on manual scheduling" do
      before do
        [grandgrandparent, grandparent, work_package].each do |wp|
          wp.update_column(:ignore_non_working_days, true)
        end

        [parent, sibling].each do |wp|
          wp.update_column(:ignore_non_working_days, false)
        end

        [parent].each do |wp|
          wp.update_column(:schedule_manually, true)
        end
      end

      it "is successful" do
        expect(subject)
          .to be_success
      end

      it "returns the former ancestors in the dependent results" do
        expect(subject.dependent_results.map(&:result))
          .to be_empty
      end

      it "sets the ignore_non_working_days property of the new ancestors" do
        subject

        expect(parent.reload.ignore_non_working_days)
          .to be_falsey

        expect(grandparent.reload.ignore_non_working_days)
          .to be_truthy

        expect(grandgrandparent.reload.ignore_non_working_days)
          .to be_truthy

        expect(sibling.reload.ignore_non_working_days)
          .to be_falsey
      end
    end
  end
end
