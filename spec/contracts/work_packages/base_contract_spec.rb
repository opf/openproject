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
require "contracts/shared/model_contract_shared_context"

RSpec.describe WorkPackages::BaseContract,
               with_flag: { percent_complete_edition: true } do
  include_context "ModelContract shared context"

  let(:work_package) do
    build_stubbed(:work_package,
                  type:,
                  done_ratio: 50,
                  estimated_hours: 6.0,
                  remaining_hours: 3.0,
                  project:)
  end
  let(:project) { build_stubbed(:project) }
  let(:current_user) { member }
  let(:permissions) do
    %i(
      view_work_packages
      view_work_package_watchers
      edit_work_packages
      add_work_package_watchers
      delete_work_package_watchers
      manage_work_package_relations
      add_work_package_notes
      assign_versions
    )
  end
  let(:changed_values) { [] }
  let(:type) { build_stubbed(:type, is_milestone:) }
  let(:is_milestone) { false }

  let(:member) { build_stubbed(:user) }

  before do
    mock_permissions_for(member) do |mock|
      mock.allow_in_project *permissions, project:
    end
  end

  subject(:contract) { described_class.new(work_package, current_user) }

  shared_examples_for "invalid if changed" do |attribute|
    before do
      allow(work_package).to receive(:changed).and_return(changed_values.map(&:to_s))
    end

    before do
      contract.validate
    end

    context "when has changed" do
      let(:changed_values) { [attribute] }

      it("is invalid") do
        expect(contract.errors.symbols_for(attribute)).to contain_exactly(:error_readonly)
      end
    end

    context "when not changed" do
      let(:changed_values) { [] }

      it("is valid") { expect(contract.errors).to be_empty }
    end
  end

  shared_examples "a parent unwritable property" do |attribute, schedule_sensitive: false|
    before do
      allow(work_package).to receive(:changed).and_return(changed_values.map(&:to_s))
    end

    context "when no parent" do
      before do
        allow(work_package)
          .to receive(:leaf?)
          .and_return(true)

        contract.validate
      end

      context "when not changed" do
        let(:changed_values) { [] }

        it("is valid") { expect(contract.errors).to be_empty }
      end

      context "when has changed" do
        let(:changed_values) { [attribute] }

        it("is valid") { expect(contract.errors).to be_empty }
      end
    end

    context "when is a parent" do
      let(:schedule_manually) { false }

      before do
        work_package.schedule_manually = schedule_manually

        allow(work_package)
          .to receive(:leaf?)
          .and_return(false)
        contract.validate
      end

      context "when not changed" do
        let(:changed_values) { [] }

        it("is valid") { expect(contract.errors).to be_empty }
      end

      context "when has changed" do
        let(:changed_values) { [attribute] }

        it("is invalid (read only)") do
          expect(contract.errors.symbols_for(attribute)).to contain_exactly(:error_readonly)
        end
      end

      if schedule_sensitive
        context "when is scheduled manually" do
          let(:schedule_manually) { true }

          context "when has changed" do
            let(:changed_values) { [attribute] }

            it("is valid") { expect(contract.errors).to be_empty }
          end
        end
      end
    end
  end

  describe "status" do
    context "for readonly status" do
      before do
        allow(work_package)
          .to receive(:readonly_status?)
          .and_return true
      end

      it "only sets status to allowed" do
        expect(contract.writable_attributes).to eq(%w[status status_id])
      end
    end

    context "when work_package has a closed version and status" do
      before do
        version = build_stubbed(:version, status: "closed")

        work_package.version = version
        allow(work_package.status)
          .to receive(:is_closed?)
          .and_return(true)
      end

      it "is not writable" do
        expect(contract).not_to be_writable(:status)
      end

      context "when we only switched into that status now" do
        before do
          allow(work_package)
            .to receive(:status_id_change)
            .and_return [1, 2]
        end

        it "is writable" do
          expect(contract).to be_writable(:status)
        end
      end
    end

    context "when status is inexistent" do
      before do
        work_package.status = Status::InexistentStatus.new
      end

      it "is invalid" do
        contract.validate

        expect(subject.errors.symbols_for(:status))
          .to contain_exactly(:does_not_exist)
      end
    end

    describe "transitions" do
      let(:roles) { [build_stubbed(:project_role)] }
      let(:valid_transition_result) { true }
      let(:new_status) { build_stubbed(:status) }
      let(:from_id) { work_package.status_id }
      let(:to_id) { new_status.id }
      let(:status_change) { work_package.status = new_status }

      before do
        new_statuses_scope = double("new statuses scope") # rubocop:disable RSpec/VerifiedDoubles

        allow(Status)
          .to receive(:find_by)
          .with(id: work_package.status_id)
          .and_return(work_package.status)

        # Breaking abstraction here to avoid mocking hell.
        # We might want to extract the assignable_... into separate
        # objects.
        allow(contract)
          .to receive(:new_statuses_allowed_from)
          .with(work_package.status)
          .and_return(new_statuses_scope)

        allow(new_statuses_scope)
          .to receive(:order_by_position)
          .and_return(new_statuses_scope)

        allow(new_statuses_scope)
          .to receive(:exists?)
          .with(new_status.id)
          .and_return(valid_transition_result)

        status_change

        contract.validate
      end

      context "when valid transition" do
        it "is valid" do
          expect(subject.errors.symbols_for(:status_id))
            .to be_empty
        end
      end

      context "when invalid transition" do
        let(:valid_transition_result) { false }

        it "is invalid" do
          expect(subject.errors.symbols_for(:status_id))
            .to contain_exactly(:status_transition_invalid)
        end
      end

      context "when status is nil" do
        let(:status_change) { work_package.status = nil }

        it "is invalid" do
          expect(subject.errors.symbols_for(:status))
            .to contain_exactly(:blank)
        end
      end

      context "when invalid transition but the type changed as well" do
        let(:valid_transition_result) { false }
        let(:status_change) do
          work_package.status = new_status
          work_package.type = build_stubbed(:type)
        end

        it "is valid" do
          expect(subject.errors.symbols_for(:status_id))
            .to be_empty
        end
      end
    end
  end

  describe "work (estimated hours)" do
    before do
      work_package.estimated_hours = estimated_hours
      work_package.remaining_hours = remaining_hours
      work_package.done_ratio = done_ratio
    end

    context "when only one being set" do
      let(:estimated_hours) { 3.0 }
      let(:remaining_hours) { nil }
      let(:done_ratio) { nil }

      include_examples "contract is valid"
    end

    context "when empty while remaining work and % complete are set" do
      let(:estimated_hours) { nil }
      let(:remaining_hours) { 2.0 }
      let(:done_ratio) { 50 }

      include_examples "contract is invalid", estimated_hours: :must_be_set_when_remaining_work_and_percent_complete_are_set
    end

    context "when empty while remaining work is set and % complete is set to an invalid value" do
      let(:estimated_hours) { nil }
      let(:remaining_hours) { 2.0 }
      let(:done_ratio) { 200 }

      include_examples "contract is invalid", estimated_hours: nil,
                                              remaining_hours: nil,
                                              done_ratio: :inclusion
    end

    context "when empty while % complete is set and remaining work is set to an invalid value" do
      let(:estimated_hours) { nil }
      let(:remaining_hours) { -2.0 }
      let(:done_ratio) { 50 }

      include_examples "contract is invalid", estimated_hours: nil,
                                              remaining_hours: :greater_than_or_equal_to,
                                              done_ratio: nil
    end

    context "when < 0" do
      let(:estimated_hours) { -1 }
      let(:remaining_hours) { nil }
      let(:done_ratio) { nil }

      include_examples "contract is invalid", estimated_hours: :greater_than_or_equal_to
    end

    context "when inferior to remaining work" do
      let(:estimated_hours) { 5.0 }
      let(:remaining_hours) { 7.0 }
      let(:done_ratio) { 50 }

      include_examples "contract is invalid", estimated_hours: :cant_be_inferior_to_remaining_work
    end
  end

  describe "total work (derived estimated hours)" do
    let(:changed_values) { [] }
    let(:attribute) { :derived_estimated_hours }

    before do
      allow(work_package).to receive(:changed).and_return(changed_values.map(&:to_s))

      contract.validate
    end

    context "when has not changed" do
      let(:changed_values) { [] }

      it("is valid") { expect(contract.errors).to be_empty }
    end

    context "when has changed" do
      let(:changed_values) { [attribute] }

      it("is invalid (read only)") do
        expect(contract.errors.symbols_for(attribute)).to contain_exactly(:error_readonly)
      end
    end
  end

  describe "remaining work (remaining hours)" do
    before do
      work_package.estimated_hours = estimated_hours
      work_package.remaining_hours = remaining_hours
      work_package.done_ratio = done_ratio
    end

    context "when it's the same as work" do
      let(:estimated_hours) { 5.0 }
      let(:remaining_hours) { 5.0 }
      let(:done_ratio) { 0 }

      include_examples "contract is valid"
    end

    context "when it's less than work" do
      let(:estimated_hours) { 5.0 }
      let(:remaining_hours) { 4.0 }
      let(:done_ratio) { 20 }

      include_examples "contract is valid"
    end

    context "when it's greater than work" do
      let(:estimated_hours) { 5.0 }
      let(:remaining_hours) { 6.0 }
      let(:done_ratio) { 0 }

      include_examples "contract is invalid", remaining_hours: :cant_exceed_work
    end

    context "when only one being set" do
      let(:estimated_hours) { nil }
      let(:remaining_hours) { 1.5 }
      let(:done_ratio) { nil }

      include_examples "contract is valid"
    end

    context "when empty while work and % complete are set" do
      let(:estimated_hours) { 3 }
      let(:remaining_hours) { nil }
      let(:done_ratio) { 50 }

      include_examples "contract is invalid", remaining_hours: :must_be_set_when_work_and_percent_complete_are_set
    end

    context "when empty while work is set and % complete is set to an invalid value" do
      let(:estimated_hours) { 3 }
      let(:remaining_hours) { nil }
      let(:done_ratio) { -1 }

      include_examples "contract is invalid", estimated_hours: nil,
                                              remaining_hours: nil,
                                              done_ratio: :inclusion
    end

    context "when empty while % complete is set and work is set to a negative value" do
      let(:estimated_hours) { -3 }
      let(:remaining_hours) { nil }
      let(:done_ratio) { 50 }

      include_examples "contract is invalid", estimated_hours: :greater_than_or_equal_to,
                                              remaining_hours: nil,
                                              done_ratio: nil
    end
  end

  describe "percent complete" do
    context "when in status-based progress calculation mode (inferred by status)",
            with_settings: { work_package_done_ratio: "status" } do
      it_behaves_like "invalid if changed", :done_ratio
    end

    context "when in work-based progress calculation mode",
            with_settings: { work_package_done_ratio: "field" } do
      before do
        work_package.estimated_hours = estimated_hours
        work_package.remaining_hours = remaining_hours
        work_package.done_ratio = done_ratio
      end

      context "when less than 0" do
        let(:estimated_hours) { nil }
        let(:remaining_hours) { nil }
        let(:done_ratio) { -1 }

        it_behaves_like "contract is invalid", done_ratio: :inclusion
      end

      context "when more than 100" do
        let(:estimated_hours) { nil }
        let(:remaining_hours) { nil }
        let(:done_ratio) { 101 }

        it_behaves_like "contract is invalid", done_ratio: :inclusion
      end

      context "when not a number" do
        let(:estimated_hours) { nil }
        let(:remaining_hours) { nil }
        let(:done_ratio) { "abc" }

        it_behaves_like "contract is invalid", done_ratio: :not_a_number
      end

      context "when only one being set" do
        let(:estimated_hours) { nil }
        let(:remaining_hours) { nil }
        let(:done_ratio) { 42 }

        it_behaves_like "contract is valid"
      end

      context "when empty while work and remaining work are set" do
        let(:estimated_hours) { 4 }
        let(:remaining_hours) { 3 }
        let(:done_ratio) { nil }

        it_behaves_like "contract is invalid", done_ratio: :must_be_set_when_work_and_remaining_work_are_set
      end

      context "when empty while work is set and remaining work is set to a negative value" do
        let(:estimated_hours) { 4 }
        let(:remaining_hours) { -3 }
        let(:done_ratio) { nil }

        it_behaves_like "contract is invalid", estimated_hours: nil,
                                               remaining_hours: :greater_than_or_equal_to,
                                               done_ratio: nil
      end

      context "when set while work is set and remaining work is set to a negative value" do
        let(:estimated_hours) { 4 }
        let(:remaining_hours) { -3 }
        let(:done_ratio) { 50 }

        include_examples "contract is invalid", estimated_hours: nil,
                                                remaining_hours: :greater_than_or_equal_to,
                                                done_ratio: nil
      end

      context "when empty while remaining work is set and work is set to a negative value" do
        let(:estimated_hours) { -4 }
        let(:remaining_hours) { 3 }
        let(:done_ratio) { nil }

        it_behaves_like "contract is invalid", estimated_hours: :greater_than_or_equal_to,
                                               remaining_hours: nil,
                                               done_ratio: nil
      end

      context "when set while remaining work is set and work is set to a negative value" do
        let(:estimated_hours) { -4 }
        let(:remaining_hours) { 3 }
        let(:done_ratio) { 50 }

        it_behaves_like "contract is invalid", estimated_hours: :greater_than_or_equal_to,
                                               remaining_hours: nil,
                                               done_ratio: nil
      end

      context "when set while work and remaining work are both set to a negative values (and work > remaining work)" do
        let(:estimated_hours) { -4 }
        let(:remaining_hours) { -12 }
        let(:done_ratio) { 50 }

        it_behaves_like "contract is invalid", estimated_hours: :greater_than_or_equal_to,
                                               remaining_hours: :greater_than_or_equal_to,
                                               done_ratio: nil
      end
    end
  end

  describe "work, remaining work, and % complete" do
    before do
      work_package.estimated_hours = estimated_hours
      work_package.remaining_hours = remaining_hours
      work_package.done_ratio = done_ratio
    end

    context "when remaining work exceeds work" do
      let(:estimated_hours) { 5.0 }
      let(:remaining_hours) { 6.0 }
      let(:done_ratio) { 50 }

      # no errors should be reported for % complete in this case to not overload
      # the progress modal with error messages.
      include_examples "contract is invalid", estimated_hours: :cant_be_inferior_to_remaining_work,
                                              remaining_hours: :cant_exceed_work,
                                              done_ratio: nil

      context "and % complete is 100%" do
        let(:done_ratio) { 100 }

        include_examples "contract is invalid",
                         estimated_hours: nil,
                         remaining_hours: :must_be_set_to_zero_hours_when_work_is_set_and_percent_complete_is_100p,
                         done_ratio: nil
      end
    end

    context "when remaining work exceeds work and done_ratio is empty" do
      let(:estimated_hours) { 5.0 }
      let(:remaining_hours) { 6.0 }
      let(:done_ratio) { nil }

      # no errors should be reported for % complete in this case to not overload
      # the progress modal with error messages.
      include_examples "contract is invalid", estimated_hours: :cant_be_inferior_to_remaining_work,
                                              remaining_hours: :cant_exceed_work,
                                              done_ratio: nil
    end

    context "when work is not a valid duration (an invalid string for instance)" do
      let(:estimated_hours) { "invalid" }
      let(:remaining_hours) { 6.0 }
      let(:done_ratio) { 50 }

      # no errors should be reported for % complete in this case to not overload
      # the progress modal with error messages.
      include_examples "contract is invalid", estimated_hours: :not_a_number,
                                              remaining_hours: nil,
                                              done_ratio: nil
    end

    context "when remaining work is not a valid duration (an invalid string for instance)" do
      let(:estimated_hours) { 10.0 }
      let(:remaining_hours) { "invalid" }
      let(:done_ratio) { 50 }

      # no errors should be reported for % complete in this case to not overload
      # the progress modal with error messages.
      include_examples "contract is invalid", estimated_hours: nil,
                                              remaining_hours: :not_a_number,
                                              done_ratio: nil
    end

    context "when work is 0h and remaining work is not a valid duration (an invalid string for instance)" do
      let(:estimated_hours) { 0.0 }
      let(:remaining_hours) { "invalid" }
      let(:done_ratio) { 50 }

      # no errors should be reported for % complete in this case to not overload
      # the progress modal with error messages.
      include_examples "contract is invalid", estimated_hours: nil,
                                              remaining_hours: :not_a_number,
                                              done_ratio: nil
    end

    context "when all three empty" do
      let(:estimated_hours) { nil }
      let(:remaining_hours) { nil }
      let(:done_ratio) { nil }

      include_examples "contract is valid"
    end

    context "when all three set with consistent values" do
      let(:estimated_hours) { 10 }
      let(:remaining_hours) { 6.0 }
      let(:done_ratio) { 40 }

      include_examples "contract is valid"
    end

    context "with inexact calculated % complete value (rounded to 1% VS 0.05% actual)" do
      let(:estimated_hours) { 2000 }
      let(:remaining_hours) { 1999 }
      let(:done_ratio) { 1 }

      include_examples "contract is valid"
    end

    context "when all three set with inconsistent values" do
      let(:estimated_hours) { 10 }
      let(:remaining_hours) { 0 }
      let(:done_ratio) { 50 }

      include_examples "contract is invalid", done_ratio: :does_not_match_work_and_remaining_work
    end

    context "when work and remaining work are both 0h" do
      let(:estimated_hours) { 0 }
      let(:remaining_hours) { 0 }

      context "when % complete is set to any value" do
        let(:done_ratio) { 50 }

        include_examples "contract is invalid", done_ratio: :cannot_be_set_when_work_is_zero
      end

      context "when % complete is set to 100%" do
        let(:done_ratio) { 100 }

        include_examples "contract is invalid", done_ratio: :cannot_be_set_when_work_is_zero
      end

      context "when % complete is empty" do
        let(:done_ratio) { nil }

        include_examples "contract is valid"
      end
    end

    context "when % complete is 100%" do
      let(:done_ratio) { 100 }

      context "and work and remaining are both set to 0h" do
        let(:estimated_hours) { 0 }
        let(:remaining_hours) { 0 }

        include_examples "contract is invalid",
                         estimated_hours: nil,
                         remaining_hours: nil,
                         done_ratio: :cannot_be_set_when_work_is_zero
      end

      context "and work is set" do
        let(:estimated_hours) { 10 }

        context "and remaining work is empty" do
          let(:remaining_hours) { nil }

          include_examples "contract is invalid",
                           estimated_hours: nil,
                           remaining_hours: :must_be_set_to_zero_hours_when_work_is_set_and_percent_complete_is_100p,
                           done_ratio: nil
        end

        context "and remaining is set to 0h" do
          let(:remaining_hours) { 0 }

          include_examples "contract is valid"
        end

        context "and remaining is set (but not 0h)" do
          let(:remaining_hours) { 5 }

          include_examples "contract is invalid",
                           estimated_hours: nil,
                           remaining_hours: :must_be_set_to_zero_hours_when_work_is_set_and_percent_complete_is_100p,
                           done_ratio: nil
        end
      end

      context "and work is empty" do
        let(:estimated_hours) { nil }

        context "and remaining work is empty" do
          let(:remaining_hours) { nil }

          include_examples "contract is valid"
        end

        context "and remaining is set to 0h" do
          let(:remaining_hours) { 0 }

          include_examples "contract is invalid", estimated_hours: nil,
                                                  remaining_hours: :must_be_empty_when_work_is_empty_and_percent_complete_is_100p,
                                                  done_ratio: nil
        end

        context "and remaining is set (but not 0h)" do
          let(:remaining_hours) { 5 }

          include_examples "contract is invalid", estimated_hours: nil,
                                                  remaining_hours: :must_be_empty_when_work_is_empty_and_percent_complete_is_100p,
                                                  done_ratio: nil
        end
      end
    end

    context "when work and remaining work are both empty" do
      let(:estimated_hours) { nil }
      let(:remaining_hours) { nil }

      context "when % complete is set to any value" do
        let(:done_ratio) { 50 }

        include_examples "contract is valid"
      end

      context "when % complete is empty" do
        let(:done_ratio) { nil }

        include_examples "contract is valid"
      end
    end
  end

  shared_examples_for "a date attribute" do |attribute|
    context "for a date" do
      before do
        work_package.send(:"#{attribute}=", Time.zone.today)
        contract.validate
      end

      it "is valid" do
        expect(subject.errors.symbols_for(attribute))
          .to be_empty
      end
    end

    context "for a string representing a date" do
      before do
        work_package.send(:"#{attribute}=", "01/01/17")
        contract.validate
      end

      it "is valid" do
        expect(subject.errors.symbols_for(attribute))
          .to be_empty
      end
    end

    context "for a non-date" do
      before do
        work_package.send(:"#{attribute}=", "not a date")
        contract.validate
      end

      it "is invalid" do
        expect(subject.errors.symbols_for(attribute))
          .to contain_exactly(:not_a_date)
      end
    end
  end

  describe "start date" do
    it_behaves_like "a parent unwritable property", :start_date, schedule_sensitive: true
    it_behaves_like "a date attribute", :start_date

    context "as before soonest start date of parent" do
      let(:schedule_manually) { false }

      before do
        work_package.schedule_manually = schedule_manually
        allow(work_package)
          .to receive(:parent)
          .and_return(build_stubbed(:work_package))
        allow(work_package)
          .to receive(:soonest_start)
          .and_return(Time.zone.today + 4.days)

        work_package.start_date = Time.zone.today + 2.days
      end

      context "when scheduled automatically" do
        it "notes the error" do
          contract.validate

          message = I18n.t("activerecord.errors.models.work_package.attributes.start_date.violates_relationships",
                           soonest_start: Time.zone.today + 4.days)

          expect(contract.errors[:start_date])
            .to contain_exactly(message)
        end
      end

      context "when scheduled manually" do
        let(:schedule_manually) { true }

        it_behaves_like "contract is valid"
      end
    end

    context "when setting due date and duration without start date" do
      before do
        work_package.duration = 1
        work_package.start_date = nil
        work_package.due_date = Time.zone.today
      end

      it_behaves_like "contract is invalid", start_date: :cannot_be_null
    end
  end

  describe "due date" do
    it_behaves_like "a parent unwritable property", :due_date, schedule_sensitive: true
    it_behaves_like "a date attribute", :due_date

    it "returns an error when trying to set it before the start date" do
      work_package.start_date = Time.zone.today + 2.days
      work_package.due_date = Time.zone.today

      contract.validate

      message = I18n.t("activerecord.errors.messages.greater_than_or_equal_to_start_date")

      expect(contract.errors[:due_date])
        .to include message
    end

    context "when start date is not set and due date is before soonest start date of parent" do
      let(:schedule_manually) { false }

      before do
        work_package.schedule_manually = schedule_manually
        allow(work_package)
          .to receive(:parent)
          .and_return(build_stubbed(:work_package))
        allow(work_package)
          .to receive(:soonest_start)
          .and_return(Time.zone.today + 4.days)

        work_package.start_date = nil
        work_package.due_date = Time.zone.today + 2.days
      end

      context "when scheduled automatically" do
        it "notes the error" do
          contract.validate

          message = I18n.t("activerecord.errors.models.work_package.attributes.start_date.violates_relationships",
                           soonest_start: Time.zone.today + 4.days)

          expect(contract.errors[:due_date])
            .to contain_exactly(message)
        end
      end

      context "when scheduled manually" do
        let(:schedule_manually) { true }

        it_behaves_like "contract is valid"
      end
    end

    context "when setting start date and duration without due date" do
      before do
        work_package.duration = 1
        work_package.start_date = Time.zone.today
        work_package.due_date = nil
      end

      it_behaves_like "contract is invalid", due_date: :cannot_be_null
    end
  end

  describe "duration" do
    context "when setting duration" do
      before do
        work_package.duration = 5
      end

      it_behaves_like "contract is valid"
    end

    context "when setting duration for a milestone type work package" do
      let(:is_milestone) { true }

      before do
        work_package.duration = 5
      end

      it_behaves_like "contract is invalid", duration: :not_available_for_milestones
    end

    context "when setting duration to nil for a milestone type work package" do
      let(:is_milestone) { true }

      before do
        work_package.duration = nil
      end

      it_behaves_like "contract is invalid"
    end

    context "when setting duration to 1 for a milestone type work package" do
      let(:is_milestone) { true }

      before do
        work_package.duration = 1
      end

      it_behaves_like "contract is valid"
    end

    context "when setting duration to 0" do
      before do
        work_package.duration = 0
      end

      it_behaves_like "contract is invalid", duration: :greater_than
    end

    context "when setting duration to a floating point" do
      before do
        work_package.duration = 4.5
      end

      it_behaves_like "contract is invalid", duration: :not_an_integer
    end

    context "when setting duration to a negative value" do
      before do
        work_package.duration = -5
      end

      it_behaves_like "contract is invalid", duration: :greater_than
    end

    context "when setting duration and dates" do
      before do
        work_package.ignore_non_working_days = true
        work_package.duration = 6
        work_package.start_date = Time.zone.today - 4.days
        work_package.due_date = Time.zone.today + 1.day
      end

      it_behaves_like "contract is valid"
    end

    context "when setting duration and dates while covering non-working days" do
      before do
        week_with_saturday_and_sunday_as_weekend
        work_package.ignore_non_working_days = false
        work_package.duration = 6
        work_package.start_date = "2022-08-22"
        work_package.due_date = "2022-08-29"
      end

      it_behaves_like "contract is valid"
    end

    context "when setting duration and dates and duration is too small" do
      before do
        work_package.ignore_non_working_days = true
        work_package.duration = 5
        work_package.start_date = Time.zone.today - 4.days
        work_package.due_date = Time.zone.today + 1.day
      end

      it_behaves_like "contract is invalid", duration: :smaller_than_dates
    end

    context "when setting duration and dates while covering non-working days and duration is too small" do
      before do
        week_with_saturday_and_sunday_as_weekend
        work_package.ignore_non_working_days = false
        work_package.duration = 1
        work_package.start_date = "2022-08-22"
        work_package.due_date = "2022-08-29"
      end

      it_behaves_like "contract is invalid", duration: :smaller_than_dates
    end

    context "when setting duration and dates and duration is too big" do
      before do
        work_package.ignore_non_working_days = true
        work_package.duration = 7
        work_package.start_date = Time.zone.today - 4.days
        work_package.due_date = Time.zone.today + 1.day
      end

      it_behaves_like "contract is invalid", duration: :larger_than_dates
    end

    context "when setting duration and dates while covering non-working days and duration is too big" do
      before do
        week_with_saturday_and_sunday_as_weekend
        work_package.ignore_non_working_days = false
        work_package.duration = 99
        work_package.start_date = "2022-08-22"
        work_package.due_date = "2022-08-29"
      end

      it_behaves_like "contract is invalid", duration: :larger_than_dates
    end

    context "when setting start date and due date without duration" do
      before do
        work_package.duration = nil
        work_package.start_date = Time.zone.today
        work_package.due_date = Time.zone.today
      end

      it_behaves_like "contract is invalid", duration: :cannot_be_null
    end
  end

  describe "ignore_non_working_days" do
    context "when setting the value to true" do
      before do
        work_package.ignore_non_working_days = true
      end

      it_behaves_like "contract is valid"
    end

    context "when setting the value to false" do
      before do
        work_package.ignore_non_working_days = false
      end

      it_behaves_like "contract is valid"
    end
  end

  describe "version" do
    subject(:contract) { described_class.new(work_package, current_user) }

    let(:assignable_version) { build_stubbed(:version) }
    let(:invalid_version) { build_stubbed(:version) }

    before do
      allow(work_package).to receive(:assignable_versions).and_return [assignable_version]
    end

    context "for assignable version" do
      before do
        work_package.version = assignable_version
        subject.validate
      end

      it "is valid" do
        expect(subject.errors).to be_empty
      end
    end

    context "for non assignable version" do
      before do
        work_package.version = invalid_version
        subject.validate
      end

      it "is invalid" do
        expect(subject.errors.symbols_for(:version_id)).to eql [:inclusion]
      end
    end

    context "for a closed version" do
      let(:assignable_version) { build_stubbed(:version, status: "closed") }

      context "when reopening a work package" do
        before do
          allow(work_package)
            .to receive(:reopened?)
            .and_return(true)

          work_package.version = assignable_version
          subject.validate
        end

        it "is invalid" do
          expect(subject.errors[:base]).to eql [I18n.t(:error_can_not_reopen_work_package_on_closed_version)]
        end
      end

      context "when not reopening the work package" do
        before do
          work_package.version = assignable_version
          subject.validate
        end

        it "is valid" do
          expect(subject.errors).to be_empty
        end
      end
    end
  end

  describe "parent" do
    let(:parent) { build_stubbed(:work_package) }

    before do
      work_package.parent = parent
    end

    subject do
      contract.validate

      # while we do validate the parent
      # the errors are still put on :base so that the messages can be reused
      contract.errors.symbols_for(:parent)
    end

    context "when self assigning" do
      let(:parent) { work_package }

      it "returns an error for the parent" do
        expect(subject)
          .to eq [:cannot_be_self_assigned]
      end
    end

    context "when the intended parent is not relatable" do
      before do
        scope = instance_double(ActiveRecord::Relation)

        allow(WorkPackage)
          .to receive(:relatable)
                .with(work_package, Relation::TYPE_PARENT)
                .and_return(scope)

        allow(scope)
          .to receive(:where)
                .with(id: parent.id)
                .and_return([])
      end

      it "is invalid" do
        expect(subject)
          .to include(:cant_link_a_work_package_with_a_descendant)
      end
    end

    context "when an invalid parent_id is set" do
      before do
        work_package.parent = nil
        work_package.parent_id = -1
      end

      it "is invalid" do
        expect(subject)
          .to include(:does_not_exist)
      end
    end
  end

  describe "type" do
    context "for disabled type" do
      before do
        allow(project)
          .to receive(:types)
          .and_return([])
      end

      describe "not changing the type" do
        it "is valid" do
          subject.validate

          expect(subject)
            .to be_valid
        end
      end

      describe "changing the type" do
        let(:other_type) { build_stubbed(:type) }

        it "is invalid" do
          work_package.type = other_type

          subject.validate

          expect(subject.errors.symbols_for(:type_id))
            .to contain_exactly(:inclusion)
        end
      end

      describe "changing the project (and that one not having the type)" do
        let(:other_project) { build_stubbed(:project) }

        it "is invalid" do
          work_package.project = other_project

          subject.validate

          expect(subject.errors.symbols_for(:type_id))
            .to contain_exactly(:inclusion)
        end
      end
    end

    context "for inexistent type" do
      before do
        work_package.type = Type::InexistentType.new

        contract.validate
      end

      it "is invalid" do
        expect(contract.errors.symbols_for(:type))
          .to contain_exactly(:does_not_exist)
      end
    end
  end

  describe "assigned_to" do
    context "for inexistent user" do
      before do
        work_package.assigned_to = Users::InexistentUser.new

        contract.validate
      end

      it "is invalid" do
        expect(contract.errors.symbols_for(:assigned_to))
          .to contain_exactly(:does_not_exist)
      end
    end
  end

  describe "category" do
    let(:category) { build_stubbed(:category) }

    context "for one of the project's categories" do
      before do
        allow(project)
          .to receive(:categories)
          .and_return [category]

        work_package.category = category

        contract.validate
      end

      it "is valid" do
        expect(contract.errors.symbols_for(:category))
          .to be_empty
      end
    end

    context "when empty" do
      before do
        work_package.category = nil

        contract.validate
      end

      it "is valid" do
        expect(contract.errors.symbols_for(:category))
          .to be_empty
      end
    end

    context "for inexistent category (e.g. removed)" do
      before do
        work_package.category_id = 5

        contract.validate
      end

      it "is invalid" do
        expect(contract.errors.symbols_for(:category))
          .to contain_exactly(:does_not_exist)
      end
    end

    context "when not of the project" do
      before do
        allow(project)
          .to receive(:categories)
          .and_return []

        work_package.category = category

        contract.validate
      end

      it "is invalid" do
        expect(contract.errors.symbols_for(:category))
          .to contain_exactly(:only_same_project_categories_allowed)
      end
    end
  end

  describe "priority" do
    let (:active_priority) { build_stubbed(:priority) }
    let (:inactive_priority) { build_stubbed(:priority, active: false) }

    context "as active priority" do
      before do
        work_package.priority = active_priority

        contract.validate
      end

      it "is valid" do
        expect(contract.errors.symbols_for(:priority_id))
          .to be_empty
      end
    end

    context "as inactive priority" do
      before do
        work_package.priority = inactive_priority

        contract.validate
      end

      it "is invalid" do
        expect(contract.errors.symbols_for(:priority_id))
          .to contain_exactly(:only_active_priorities_allowed)
      end
    end

    context "as inactive priority but priority not changed" do
      before do
        work_package.priority = inactive_priority
        work_package.clear_changes_information

        contract.validate
      end

      it "is valid" do
        expect(contract.errors.symbols_for(:priority_id))
          .to be_empty
      end
    end

    context "as inexistent priority" do
      before do
        work_package.priority = Priority::InexistentPriority.new

        contract.validate
      end

      it "is invalid" do
        expect(contract.errors.symbols_for(:priority))
          .to contain_exactly(:does_not_exist)
      end
    end
  end

  describe "#assignable_statuses" do
    let(:role) { build_stubbed(:project_role) }
    let(:type) { build_stubbed(:type) }
    let(:assignee_user) { build_stubbed(:user) }
    let(:author_user) { build_stubbed(:user) }
    let(:current_status) { build_stubbed(:status) }
    let(:version) { build_stubbed(:version) }
    let(:work_package) do
      build_stubbed(:work_package,
                    assigned_to: assignee_user,
                    author: author_user,
                    status: current_status,
                    version:,
                    type:)
    end
    let!(:default_status) do
      status = build_stubbed(:status)

      allow(Status)
        .to receive(:default)
        .and_return(status)

      status
    end

    let(:roles) { [role] }

    before do
      allow(current_user)
        .to receive(:roles_for_work_package)
         .with(work_package)
         .and_return(roles)
    end

    shared_examples_for "new_statuses_allowed_to" do
      let(:base_scope) do
        from_workflows = Workflow
                        .from_status(current_status.id, type.id, [role.id], author, assignee)
                        .select(:new_status_id)

        Status.where(id: from_workflows)
          .or(Status.where(id: current_status.id))
      end

      it "returns a scope that returns current_status and those available by workflow" do
        expect(contract.assignable_statuses.to_sql)
          .to eql base_scope.order_by_position.to_sql
      end

      it "removes closed statuses if blocked" do
        allow(work_package)
          .to receive(:blocked?)
          .and_return(true)

        expected = base_scope.where(is_closed: false).order_by_position

        expect(contract.assignable_statuses.to_sql)
          .to eql expected.to_sql
      end

      context "if the current status is closed and the version is closed as well" do
        let(:version) { build_stubbed(:version, status: "closed") }
        let(:current_status) { build_stubbed(:status, is_closed: true) }

        it "only allows the current status" do
          expect(contract.assignable_statuses.to_sql)
            .to eql Status.where(id: current_status.id).to_sql
        end
      end
    end

    context "with somebody else asking" do
      it_behaves_like "new_statuses_allowed_to" do
        let(:author) { false }
        let(:assignee) { false }
      end
    end

    context "with the author asking" do
      let(:current_user) { author_user }

      it_behaves_like "new_statuses_allowed_to" do
        let(:author) { true }
        let(:assignee) { false }
      end
    end

    context "with the assignee asking" do
      let(:current_user) { assignee_user }

      it_behaves_like "new_statuses_allowed_to" do
        let(:author) { false }
        let(:assignee) { true }
      end
    end

    context "with the assignee changing and asking as new assignee" do
      before do
        work_package.assigned_to = current_user
      end

      # is using the former assignee
      it_behaves_like "new_statuses_allowed_to" do
        let(:author) { false }
        let(:assignee) { false }
      end
    end

    context "with the status having changed" do
      let(:new_status) { build_stubbed(:status) }

      before do
        allow(work_package).to receive(:persisted?).and_return(true)
        allow(work_package).to receive(:status_id_changed?).and_return(true)

        allow(Status)
          .to receive(:find_by)
          .with(id: work_package.status_id_was)
          .and_return(current_status)

        work_package.status = new_status
      end

      it_behaves_like "new_statuses_allowed_to" do
        let(:author) { false }
        let(:assignee) { false }
      end
    end
  end

  describe "#assignable_types" do
    let(:scope) do
      instance_double(ActiveRecord::Querying).tap do |s|
        allow(s)
          .to receive(:includes)
          .and_return(s)
      end
    end

    context "when project nil" do
      before do
        work_package.project = nil
      end

      it "is all types" do
        allow(Type)
          .to receive(:includes)
          .and_return(scope)

        expect(contract.assignable_types)
          .to eql(scope)
      end
    end

    context "when project defined" do
      it "is all types of the project" do
        allow(work_package.project)
          .to receive(:types)
          .and_return(scope)

        expect(contract.assignable_types)
          .to eql(scope)
      end
    end
  end

  describe "#assignable_versions" do
    let(:result) { double }

    it "calls through to the work package" do
      allow(work_package).to receive(:assignable_versions).and_return(result)
      expect(subject.assignable_values(:version, current_user)).to eql(result)
      expect(work_package).to have_received(:assignable_versions)
    end
  end

  describe "#assignable_priorities" do
    let(:active_priority) { build(:priority, active: true) }
    let(:inactive_priority) { build(:priority, active: false) }

    before do
      active_priority.save!
      inactive_priority.save!
    end

    it "returns only active priorities" do
      expect(subject.assignable_values(:priority, current_user).size).to be >= 1
      subject.assignable_values(:priority, current_user).each do |priority|
        expect(priority.active).to be_truthy
      end
    end
  end

  describe "#assignable_categories" do
    let(:category) { instance_double(Category) }

    before do
      allow(project).to receive(:categories).and_return([category])
    end

    it "returns all categories of the project" do
      expect(subject.assignable_values(:category, current_user)).to contain_exactly(category)
    end
  end

  include_examples "contract reuses the model errors"
end
