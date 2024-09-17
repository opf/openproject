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

RSpec.describe WorkPackages::SetAttributesService,
               type: :model,
               with_flag: { percent_complete_edition: true } do
  shared_let(:status_0_pct_complete) { create(:status, default_done_ratio: 0, name: "0% complete") }
  shared_let(:status_50_pct_complete) { create(:status, default_done_ratio: 50, name: "50% complete") }
  shared_let(:status_70_pct_complete) { create(:status, default_done_ratio: 70, name: "70% complete") }

  let(:today) { Time.zone.today }
  let(:user) { build_stubbed(:user) }
  let(:project) do
    p = build_stubbed(:project)
    allow(p).to receive(:shared_versions).and_return([])

    p
  end
  let(:work_package) do
    wp = build_stubbed(:work_package, project:, status: status_0_pct_complete)
    wp.type = initial_type
    wp.clear_changes_information

    wp
  end
  let(:new_work_package) do
    WorkPackage.new
  end
  let(:initial_type) { build_stubbed(:type) }
  let(:milestone_type) { build_stubbed(:type_milestone) }
  let(:statuses) { [] }
  let(:contract_class) { WorkPackages::UpdateContract }
  let(:mock_contract) do
    class_double(contract_class,
                 new: mock_contract_instance)
  end
  let(:mock_contract_instance) do
    instance_double(contract_class,
                    assignable_statuses: statuses,
                    errors: contract_errors,
                    validate: contract_valid)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    instance_double(ActiveModel::Errors)
  end
  let(:instance) do
    described_class.new(user:,
                        model: work_package,
                        contract_class: mock_contract)
  end

  shared_examples_for "service call" do |description: nil|
    subject do
      allow(work_package)
        .to receive(:save)

      instance.call(call_attributes)
    end

    it description || "sets the value" do
      all_expected_attributes = {}
      all_expected_attributes.merge!(expected_attributes) if defined?(expected_attributes)
      if defined?(expected_kept_attributes)
        kept = work_package.attributes.slice(*expected_kept_attributes)
        if kept.size != expected_kept_attributes.size
          raise ArgumentError, "expected_kept_attributes contains attributes that are not present in the work_package: " \
                               "#{expected_kept_attributes - kept.keys} not present in #{work_package.attributes}"
        end
        all_expected_attributes.merge!(kept)
      end
      next if all_expected_attributes.blank?

      subject

      aggregate_failures do
        expect(subject).to be_success
        expect(work_package).to have_attributes(all_expected_attributes)
        # work package is not saved and no errors are created by the service
        # (that's contract's responsibility and it is mocked in this test)
        expect(work_package).not_to have_received(:save)
        expect(subject.errors).to be_empty
      end
    end

    context "when the contract does not validate" do
      let(:contract_valid) { false }

      it "is unsuccessful, does not persist the changes and exposes the contract's errors", :aggregate_failures do
        expect(subject).not_to be_success
        expect(work_package).not_to have_received(:save)
        expect(subject.errors).to eql mock_contract_instance.errors
      end
    end
  end

  context "when updating subject before calling the service" do
    let(:call_attributes) { {} }
    let(:expected_attributes) { { subject: "blubs blubs" } }

    before do
      work_package.attributes = expected_attributes
    end

    it_behaves_like "service call"
  end

  context "when updating subject via attributes" do
    let(:call_attributes) { expected_attributes }
    let(:expected_attributes) { { subject: "blubs blubs" } }

    it_behaves_like "service call"
  end

  # Scenarios specified in https://community.openproject.org/wp/40749
  # Just checking that everything is correctly wired up. All other scenarios tested in:
  # - spec/services/work_packages/set_attributes_service/update_progress_values_status_based_spec.rb
  # - spec/services/work_packages/set_attributes_service/update_progress_values_work_based_spec.rb
  describe "deriving progress values attributes" do
    context "in status-based mode",
            with_settings: { work_package_done_ratio: "status" } do
      context "given a work package with work, remaining work, and status with % complete being set" do
        before do
          work_package.status = status_50_pct_complete
          work_package.done_ratio = work_package.status.default_done_ratio
          work_package.estimated_hours = 10.0
          work_package.remaining_hours = 5.0
          work_package.clear_changes_information
        end

        context "when work is changed" do
          let(:call_attributes) { { estimated_hours: 5.0 } }
          let(:expected_attributes) { { remaining_hours: 2.5 } }

          it_behaves_like "service call", description: "recomputes remaining work accordingly"
        end

        context "when another status is set" do
          let(:call_attributes) { { status: status_70_pct_complete } }
          let(:expected_attributes) { { remaining_hours: 3.0, done_ratio: 70 } }

          it_behaves_like "service call",
                          description: "sets the % complete value to the status default % complete value " \
                                       "and recomputes remaining work accordingly"
        end
      end

      context "given a work package with work and remaining work being empty, and a status with 0% complete" do
        before do
          work_package.status = status_0_pct_complete
          work_package.done_ratio = work_package.status.default_done_ratio
          work_package.estimated_hours = nil
          work_package.remaining_hours = nil
          work_package.clear_changes_information
        end

        context "when another status with another % complete value is set" do
          let(:call_attributes) { { status: status_70_pct_complete } }
          let(:expected_attributes) { { remaining_hours: nil } }

          it_behaves_like "service call",
                          description: "remaining work remains empty"
        end

        context "when work is set" do
          let(:call_attributes) { { estimated_hours: 10.0 } }
          let(:expected_attributes) { { remaining_hours: 10.0 } }

          it_behaves_like "service call",
                          description: "remaining work is derived from work and % complete value of the status"
        end
      end
    end

    context "in work-based mode",
            with_settings: { work_package_done_ratio: "field" } do
      context "given a work package with work, remaining work, and % complete being set" do
        before do
          work_package.estimated_hours = 10.0
          work_package.remaining_hours = 3.0
          work_package.done_ratio = 70
          work_package.clear_changes_information
        end

        context "when remaining work is cleared" do
          let(:call_attributes) { { remaining_hours: nil } }
          let(:expected_attributes) { { estimated_hours: nil, done_ratio: 70 } }

          it_behaves_like "service call", description: "keeps % complete, and clears work"
        end

        context "when work is increased" do
          # work changed by +10h
          let(:call_attributes) { { estimated_hours: 10.0 + 10.0 } }
          let(:expected_attributes) do
            { remaining_hours: 3.0 + 10.0, done_ratio: 35 }
          end

          it_behaves_like "service call",
                          description: "remaining work is increased by the same amount, and % complete is derived"
        end

        context "when work and remaining work are both changed to values with more than 2 decimals" do
          let(:call_attributes) { { estimated_hours: 10.123456, remaining_hours: 5.6789 } }
          let(:expected_attributes) { { estimated_hours: 10.12, remaining_hours: 5.68, done_ratio: 44 } }

          it_behaves_like "service call", description: "rounds work and remaining work to 2 decimals " \
                                                       "and updates % complete accordingly"
        end

        context "when remaining work is changed to a value greater than work" do
          let(:call_attributes) { { remaining_hours: 200.0 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "is an error state (to be detected by contract), and % Complete is kept"
        end

        context "when both work and remaining work are changed" do
          let(:call_attributes) { { estimated_hours: 20, remaining_hours: 2 } }
          let(:expected_attributes) { call_attributes.merge(done_ratio: 90) }

          it_behaves_like "service call", description: "updates % complete accordingly"
        end
      end

      context "given a work package with work and remaining work being empty, and % complete being set" do
        before do
          work_package.estimated_hours = nil
          work_package.remaining_hours = nil
          work_package.done_ratio = 60
          work_package.clear_changes_information
        end

        context "when work is set" do
          let(:call_attributes) { { estimated_hours: 10.0 } }
          let(:expected_attributes) { { remaining_hours: 4.0 } }
          let(:expected_kept_attributes) { %w[done_ratio] }

          it_behaves_like "service call", description: "% complete is kept and remaining work is derived"
        end
      end

      context "given a work package with work, remaining work, and % complete being empty" do
        before do
          work_package.estimated_hours = nil
          work_package.remaining_hours = nil
          work_package.done_ratio = nil
          work_package.clear_changes_information
        end

        context "when work is set" do
          let(:call_attributes) { { estimated_hours: 10.0 } }
          let(:expected_attributes) do
            { remaining_hours: 10.0, done_ratio: 0 }
          end

          it_behaves_like "service call", description: "remaining work is set to the same value and % complete is set to 0%"
        end
      end
    end
  end

  context "for status" do
    let(:default_status) { build_stubbed(:default_status) }
    let(:other_status) { build_stubbed(:status) }
    let(:new_statuses) { [other_status, default_status] }

    before do
      allow(Status)
        .to receive(:default)
              .and_return(default_status)
    end

    context "with no value set before for a new work package" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { { status: default_status } }
      let(:work_package) { new_work_package }

      before do
        work_package.status = nil
      end

      it_behaves_like "service call"
    end

    context "with an invalid value that is not part of the type.statuses for a new work package" do
      let(:invalid_status) { create(:status) }
      let(:type) { create(:type) }
      let(:call_attributes) { { status: invalid_status, type: } }
      let(:expected_attributes) { { status: default_status, type: } }
      let(:work_package) { new_work_package }

      it_behaves_like "service call"
    end

    context "with valid value and without a type present for a new work package" do
      let(:status) { create(:status) }
      let(:call_attributes) { { status:, type: nil } }
      let(:expected_attributes) { { status: } }
      let(:work_package) { new_work_package }

      it_behaves_like "service call"
    end

    context "with a valid value that is part of the type.statuses for a new work package" do
      let(:type) { create(:type) }
      let(:status) { create(:status, workflow_for_type: type) }
      let(:call_attributes) { { status:, type: } }
      let(:expected_attributes) { { status:, type: } }
      let(:work_package) { new_work_package }

      it_behaves_like "service call"
    end

    context "with no value set on existing work package" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { {} }

      before do
        work_package.status = nil
      end

      it_behaves_like "service call" do
        it "stays nil" do
          subject

          expect(work_package.status)
            .to be_nil
        end
      end
    end

    context "when updating status before calling the service" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { { status: other_status } }

      before do
        work_package.attributes = expected_attributes
      end

      it_behaves_like "service call"
    end

    context "when updating status via attributes" do
      let(:call_attributes) { expected_attributes }
      let(:expected_attributes) { { status: other_status } }

      it_behaves_like "service call"
    end
  end

  context "for author" do
    let(:other_user) { build_stubbed(:user) }

    context "with no value set before for a new work package" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { {} }
      let(:work_package) { new_work_package }

      it_behaves_like "service call" do
        it "sets the service's author" do
          subject

          expect(work_package.author)
            .to eql user
        end

        it "notes the author to be system changed" do
          subject

          expect(work_package.changed_by_system["author_id"])
            .to eql [nil, user.id]
        end
      end
    end

    context "with no value set on existing work package" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { {} }

      before do
        work_package.author = nil
      end

      it_behaves_like "service call" do
        it "stays nil" do
          subject

          expect(work_package.author)
            .to be_nil
        end
      end
    end

    context "when updating author before calling the service" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { { author: other_user } }

      before do
        work_package.attributes = expected_attributes
      end

      it_behaves_like "service call"
    end

    context "when updating author via attributes" do
      let(:call_attributes) { expected_attributes }
      let(:expected_attributes) { { author: other_user } }

      it_behaves_like "service call"
    end
  end

  context "with the actual contract" do
    let(:invalid_wp) do
      build(:work_package, subject: "").tap do |wp|
        wp.save!(validate: false)
      end
    end
    let(:user) { build_stubbed(:admin) }
    let(:instance) do
      described_class.new(user:,
                          model: invalid_wp,
                          contract_class:)
    end

    context "with a currently invalid subject" do
      let(:call_attributes) { expected_attributes }
      let(:expected_attributes) { { subject: "ABC" } }
      let(:contract_valid) { true }

      subject { instance.call(call_attributes) }

      it "is successful" do
        expect(subject).to be_success
        expect(subject.errors).to be_empty
      end
    end
  end

  context "for start_date & due_date & duration" do
    context "with a parent" do
      let(:expected_attributes) { {} }
      let(:work_package) { new_work_package }
      let(:parent) do
        build_stubbed(:work_package,
                      start_date: parent_start_date,
                      due_date: parent_due_date)
      end
      let(:parent_start_date) { Time.zone.today - 5.days }
      let(:parent_due_date) { Time.zone.today + 10.days }

      context "with the parent having dates and not providing own dates" do
        let(:call_attributes) { { parent: } }

        it_behaves_like "service call" do
          it "sets the start_date to the parent`s start_date" do
            subject

            expect(work_package.start_date)
              .to eql parent_start_date
          end

          it "sets the due_date to the parent`s due_date" do
            subject

            expect(work_package.due_date)
              .to eql parent_due_date
          end
        end
      end

      context "with the parent having dates and not providing own dates and with the parent`s" \
              "soonest_start being before the start_date (e.g. because the parent is manually scheduled)" do
        let(:call_attributes) { { parent: } }

        before do
          allow(parent)
            .to receive(:soonest_start)
                  .and_return(parent_start_date + 3.days)
        end

        it_behaves_like "service call" do
          it "sets the start_date to the parent`s start_date" do
            subject

            expect(work_package.start_date)
              .to eql parent_start_date
          end

          it "sets the due_date to the parent`s due_date" do
            subject

            expect(work_package.due_date)
              .to eql parent_due_date
          end
        end
      end

      context "with the parent having start date (no due) and not providing own dates" do
        let(:call_attributes) { { parent: } }
        let(:parent_due_date) { nil }

        it_behaves_like "service call" do
          it "sets the start_date to the parent`s start_date" do
            subject

            expect(work_package.start_date)
              .to eql parent_start_date
          end

          it "sets the due_date to nil" do
            subject

            expect(work_package.due_date)
              .to be_nil
          end
        end
      end

      context "with the parent having due date (no start) and not providing own dates" do
        let(:call_attributes) { { parent: } }
        let(:parent_start_date) { nil }

        it_behaves_like "service call" do
          it "sets the start_date to nil" do
            subject

            expect(work_package.start_date)
              .to be_nil
          end

          it "sets the due_date to the parent`s due_date" do
            subject

            expect(work_package.due_date)
              .to eql parent_due_date
          end
        end
      end

      context "with the parent having dates but providing own dates" do
        let(:call_attributes) { { parent:, start_date: Time.zone.today, due_date: Time.zone.today + 1.day } }

        it_behaves_like "service call" do
          it "sets the start_date to the provided date" do
            subject

            expect(work_package.start_date)
              .to eql Time.zone.today
          end

          it "sets the due_date to the provided date" do
            subject

            expect(work_package.due_date)
              .to eql Time.zone.today + 1.day
          end
        end
      end

      context "with the parent having dates but providing own start_date" do
        let(:call_attributes) { { parent:, start_date: Time.zone.today } }

        it_behaves_like "service call" do
          it "sets the start_date to the provided date" do
            subject

            expect(work_package.start_date)
              .to eql Time.zone.today
          end

          it "sets the due_date to the parent's due_date" do
            subject

            expect(work_package.due_date)
              .to eql parent_due_date
          end
        end
      end

      context "with the parent having dates but providing own due_date" do
        let(:call_attributes) { { parent:, due_date: Time.zone.today + 4.days } }

        it_behaves_like "service call" do
          it "sets the start_date to the parent's start date" do
            subject

            expect(work_package.start_date)
              .to eql parent_start_date
          end

          it "sets the due_date to the provided date" do
            subject

            expect(work_package.due_date)
              .to eql Time.zone.today + 4.days
          end
        end
      end

      context "with the parent having dates but providing own empty start_date" do
        let(:call_attributes) { { parent:, start_date: nil } }

        it_behaves_like "service call" do
          it "sets the start_date to nil" do
            subject

            expect(work_package.start_date)
              .to be_nil
          end

          it "sets the due_date to the parent's due_date" do
            subject

            expect(work_package.due_date)
              .to eql parent_due_date
          end
        end
      end

      context "with the parent having dates but providing own empty due_date" do
        let(:call_attributes) { { parent:, due_date: nil } }

        it_behaves_like "service call" do
          it "sets the start_date to the parent's start date" do
            subject

            expect(work_package.start_date)
              .to eql parent_start_date
          end

          it "sets the due_date to nil" do
            subject

            expect(work_package.due_date)
              .to be_nil
          end
        end
      end

      context "with the parent having dates but providing a start date that is before parent`s due date`" do
        let(:call_attributes) { { parent:, start_date: parent_due_date - 4.days } }

        it_behaves_like "service call" do
          it "sets the start_date to the provided date" do
            subject

            expect(work_package.start_date)
              .to eql parent_due_date - 4.days
          end

          it "sets the due_date to the parent's due_date" do
            subject

            expect(work_package.due_date)
              .to eql parent_due_date
          end
        end
      end

      context "with the parent having dates but providing a start date that is after the parent`s due date`" do
        let(:call_attributes) { { parent:, start_date: parent_due_date + 1.day } }

        it_behaves_like "service call" do
          it "sets the start_date to the provided date" do
            subject

            expect(work_package.start_date)
              .to eql parent_due_date + 1.day
          end

          it "leaves the due date empty" do
            subject

            expect(work_package.due_date)
              .to be_nil
          end
        end
      end

      context "with the parent having dates but providing a due date that is before the parent`s start date`" do
        let(:call_attributes) { { parent:, due_date: parent_start_date - 3.days } }

        it_behaves_like "service call" do
          it "leaves the start date empty" do
            subject

            expect(work_package.start_date)
              .to be_nil
          end

          it "set the due date to the provided date" do
            subject

            expect(work_package.due_date)
              .to eql parent_start_date - 3.days
          end
        end
      end

      context "with providing a parent_id that is invalid" do
        let(:call_attributes) { { parent_id: -1 } }
        let(:work_package) { build_stubbed(:work_package, start_date: Time.zone.today, due_date: Time.zone.today + 2.days) }

        it_behaves_like "service call" do
          it "sets the start_date to the parent`s start_date" do
            subject

            expect(work_package.start_date)
              .to eql Time.zone.today
          end

          it "sets the due_date to the parent`s due_date" do
            subject

            expect(work_package.due_date)
              .to eql Time.zone.today + 2.days
          end
        end
      end
    end

    context "with no value set for a new work package and with default setting active",
            with_settings: { work_package_startdate_is_adddate: true } do
      let(:call_attributes) { {} }
      let(:expected_attributes) { {} }
      let(:work_package) { new_work_package }

      it_behaves_like "service call" do
        it "sets the start date to today" do
          subject

          expect(work_package.start_date)
            .to eql Time.zone.today
        end

        it "sets the duration to nil" do
          subject

          expect(work_package.duration)
            .to be_nil
        end

        context "when the work package type is milestone" do
          before do
            work_package.type = milestone_type
          end

          it "sets the duration to 1" do
            subject

            expect(work_package.duration)
              .to eq 1
          end
        end
      end
    end

    context "with a value set for a new work package and with default setting active",
            with_settings: { work_package_startdate_is_adddate: true } do
      let(:call_attributes) { { start_date: Time.zone.today + 1.day } }
      let(:expected_attributes) { {} }
      let(:work_package) { new_work_package }

      it_behaves_like "service call" do
        it "stays that value" do
          subject

          expect(work_package.start_date)
            .to eq(Time.zone.today + 1.day)
        end

        it "sets the duration to nil" do
          subject

          expect(work_package.duration)
            .to be_nil
        end

        context "when the work package type is milestone" do
          before do
            work_package.type = milestone_type
          end

          it "sets the duration to 1" do
            subject

            expect(work_package.duration)
              .to eq 1
          end
        end
      end
    end

    context "with date values set to the same date on a new work package" do
      let(:call_attributes) { { start_date: Time.zone.today, due_date: Time.zone.today } }
      let(:expected_attributes) { {} }
      let(:work_package) { new_work_package }

      it_behaves_like "service call" do
        it "sets the start date value" do
          subject

          expect(work_package.start_date)
            .to eq(Time.zone.today)
        end

        it "sets the due date value" do
          subject

          expect(work_package.due_date)
            .to eq(Time.zone.today)
        end

        it "sets the duration to 1" do
          subject

          expect(work_package.duration)
            .to eq 1
        end
      end
    end

    context "with date values set on a new work package" do
      let(:call_attributes) { { start_date: Time.zone.today, due_date: Time.zone.today + 5.days } }
      let(:expected_attributes) { {} }
      let(:work_package) { new_work_package }

      it_behaves_like "service call" do
        it "sets the start date value" do
          subject

          expect(work_package.start_date)
            .to eq(Time.zone.today)
        end

        it "sets the due date value" do
          subject

          expect(work_package.due_date)
            .to eq(Time.zone.today + 5.days)
        end

        it "sets the duration to 6" do
          subject

          expect(work_package.duration)
            .to eq 6
        end
      end
    end

    context "with start date changed" do
      let(:work_package) { build_stubbed(:work_package, start_date: Time.zone.today, due_date: Time.zone.today + 5.days) }
      let(:call_attributes) { { start_date: Time.zone.today + 1.day } }
      let(:expected_attributes) { {} }

      it_behaves_like "service call" do
        it "sets the start date value" do
          subject

          expect(work_package.start_date)
            .to eq(Time.zone.today + 1.day)
        end

        it "keeps the due date value" do
          subject

          expect(work_package.due_date)
            .to eq(Time.zone.today + 5.days)
        end

        it "updates the duration" do
          subject

          expect(work_package.duration)
            .to eq 5
        end
      end
    end

    context "with due date changed" do
      let(:work_package) { build_stubbed(:work_package, start_date: Time.zone.today, due_date: Time.zone.today + 5.days) }
      let(:call_attributes) { { due_date: Time.zone.today + 1.day } }
      let(:expected_attributes) { {} }

      it_behaves_like "service call" do
        it "keeps the start date value" do
          subject

          expect(work_package.start_date)
            .to eq(Time.zone.today)
        end

        it "sets the due date value" do
          subject

          expect(work_package.due_date)
            .to eq(Time.zone.today + 1.day)
        end

        it "updates the duration" do
          subject

          expect(work_package.duration)
            .to eq 2
        end
      end
    end

    context "with start date nilled" do
      let(:traits) { [] }
      let(:work_package) do
        build_stubbed(:work_package, *traits, start_date: Time.zone.today, due_date: Time.zone.today + 5.days)
      end
      let(:call_attributes) { { start_date: nil } }
      let(:expected_attributes) { {} }

      it_behaves_like "service call" do
        it "sets the start date to nil" do
          subject

          expect(work_package.start_date)
            .to be_nil
        end

        it "keeps the due date value" do
          subject

          expect(work_package.due_date)
            .to eq(Time.zone.today + 5.days)
        end

        it "sets the duration to nil" do
          subject

          expect(work_package.duration)
            .to be_nil
        end

        context "when the work package type is milestone" do
          let(:traits) { [:is_milestone] }

          it "sets the duration to 1" do
            subject

            expect(work_package.duration)
              .to eq 1
          end
        end
      end
    end

    context "with due date nilled" do
      let(:traits) { [] }
      let(:work_package) do
        build_stubbed(:work_package, *traits, start_date: Time.zone.today, due_date: Time.zone.today + 5.days)
      end
      let(:call_attributes) { { due_date: nil } }
      let(:expected_attributes) { {} }

      it_behaves_like "service call" do
        it "keeps the start date" do
          subject

          expect(work_package.start_date)
            .to eq(Time.zone.today)
        end

        it "nils the due date" do
          subject

          expect(work_package.due_date)
            .to be_nil
        end

        it "sets the duration to nil" do
          subject

          expect(work_package.duration)
            .to be_nil
        end

        context "when the work package type is milestone" do
          let(:traits) { [:is_milestone] }

          it "sets the duration to 1" do
            subject

            expect(work_package.duration)
              .to eq 1
          end
        end
      end
    end

    context "when deriving one value from the two others" do
      # rubocop:disable Layout/ExtraSpacing, Layout/SpaceInsideArrayPercentLiteral, Layout/SpaceInsidePercentLiteralDelimiters, Layout/LineLength
      all_possible_scenarios = [
        { initial: %i[start_date  due_date  duration], set: %i[], expected: {} },
        { initial: %i[start_date                    ], set: %i[], expected: {} },
        { initial: %i[            due_date          ], set: %i[], expected: {} },
        { initial: %i[                      duration], set: %i[], expected: {} },
        { initial: %i[                              ], set: %i[], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[start_date], expected: { change: :duration } },
        { initial: %i[start_date                    ], set: %i[start_date], expected: {} },
        { initial: %i[            due_date          ], set: %i[start_date], expected: { change: :duration } },
        { initial: %i[                      duration], set: %i[start_date], expected: { change: :due_date } },
        { initial: %i[                              ], set: %i[start_date], expected: {} },

        { initial: %i[start_date  due_date  duration], nilled: %i[start_date], expected: { nilify: :duration } },
        { initial: %i[start_date                    ], nilled: %i[start_date], expected: {} },
        { initial: %i[            due_date          ], nilled: %i[start_date], expected: {} },
        { initial: %i[                      duration], nilled: %i[start_date], expected: {} },
        { initial: %i[                              ], nilled: %i[start_date], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[due_date], expected: { change: :duration } },
        { initial: %i[start_date                    ], set: %i[due_date], expected: { change: :duration } },
        { initial: %i[            due_date          ], set: %i[due_date], expected: {} },
        { initial: %i[                      duration], set: %i[due_date], expected: { change: :start_date } },
        { initial: %i[                              ], set: %i[due_date], expected: {} },

        { initial: %i[start_date  due_date  duration], nilled: %i[due_date], expected: { nilify: :duration } },
        { initial: %i[start_date                    ], nilled: %i[due_date], expected: {} },
        { initial: %i[            due_date          ], nilled: %i[due_date], expected: {} },
        { initial: %i[                      duration], nilled: %i[due_date], expected: {} },
        { initial: %i[                              ], nilled: %i[due_date], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[duration], expected: { change: :due_date } },
        { initial: %i[start_date                    ], set: %i[duration], expected: { change: :due_date } },
        { initial: %i[            due_date          ], set: %i[duration], expected: { change: :start_date } },
        { initial: %i[                      duration], set: %i[duration], expected: {} },
        { initial: %i[                              ], set: %i[duration], expected: {} },

        { initial: %i[start_date  due_date  duration], nilled: %i[duration], expected: { nilify: :due_date } },
        { initial: %i[start_date                    ], nilled: %i[duration], expected: {} },
        { initial: %i[            due_date          ], nilled: %i[duration], expected: {} },
        { initial: %i[                      duration], nilled: %i[duration], expected: {} },
        { initial: %i[                              ], nilled: %i[duration], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[start_date due_date], expected: { change: :duration } },
        { initial: %i[start_date                    ], set: %i[start_date due_date], expected: { change: :duration } },
        { initial: %i[            due_date          ], set: %i[start_date due_date], expected: { change: :duration } },
        { initial: %i[                      duration], set: %i[start_date due_date], expected: { change: :duration } },
        { initial: %i[                              ], set: %i[start_date due_date], expected: { change: :duration } },

        { initial: %i[start_date  due_date  duration], set: %i[start_date], nilled: %i[due_date], expected: { nilify: :duration } },
        { initial: %i[start_date                    ], set: %i[start_date], nilled: %i[due_date], expected: {} },
        { initial: %i[            due_date          ], set: %i[start_date], nilled: %i[due_date], expected: {} },
        { initial: %i[                      duration], set: %i[start_date], nilled: %i[due_date], expected: { nilify: :duration, same: :due_date } },
        { initial: %i[                              ], set: %i[start_date], nilled: %i[due_date], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[due_date], nilled: %i[start_date], expected: { nilify: :duration } },
        { initial: %i[start_date                    ], set: %i[due_date], nilled: %i[start_date], expected: {} },
        { initial: %i[            due_date          ], set: %i[due_date], nilled: %i[start_date], expected: {} },
        { initial: %i[                      duration], set: %i[due_date], nilled: %i[start_date], expected: { nilify: :duration, same: :start_date } },
        { initial: %i[                              ], set: %i[due_date], nilled: %i[start_date], expected: {} },

        { initial: %i[start_date  due_date  duration], nilled: %i[start_date due_date], expected: {} },
        { initial: %i[start_date                    ], nilled: %i[start_date due_date], expected: {} },
        { initial: %i[            due_date          ], nilled: %i[start_date due_date], expected: {} },
        { initial: %i[                      duration], nilled: %i[start_date due_date], expected: {} },
        { initial: %i[                              ], nilled: %i[start_date due_date], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[start_date duration], expected: { change: :due_date } },
        { initial: %i[start_date                    ], set: %i[start_date duration], expected: { change: :due_date } },
        { initial: %i[            due_date          ], set: %i[start_date duration], expected: { change: :due_date } },
        { initial: %i[                      duration], set: %i[start_date duration], expected: { change: :due_date } },
        { initial: %i[                              ], set: %i[start_date duration], expected: { change: :due_date } },

        { initial: %i[start_date  due_date  duration], set: %i[start_date], nilled: %i[duration], expected: { nilify: :due_date } },
        { initial: %i[start_date                    ], set: %i[start_date], nilled: %i[duration], expected: {} },
        { initial: %i[            due_date          ], set: %i[start_date], nilled: %i[duration], expected: { nilify: :due_date, same: :duration } },
        { initial: %i[                      duration], set: %i[start_date], nilled: %i[duration], expected: {} },
        { initial: %i[                              ], set: %i[start_date], nilled: %i[duration], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[duration], nilled: %i[start_date], expected: { nilify: :due_date } },
        { initial: %i[start_date                    ], set: %i[duration], nilled: %i[start_date], expected: {} },
        { initial: %i[            due_date          ], set: %i[duration], nilled: %i[start_date], expected: { nilify: :due_date, same: :start_date } },
        { initial: %i[                      duration], set: %i[duration], nilled: %i[start_date], expected: {} },
        { initial: %i[                              ], set: %i[duration], nilled: %i[start_date], expected: {} },

        { initial: %i[start_date  due_date  duration], nilled: %i[start_date duration], expected: {} },
        { initial: %i[start_date                    ], nilled: %i[start_date duration], expected: {} },
        { initial: %i[            due_date          ], nilled: %i[start_date duration], expected: {} },
        { initial: %i[                      duration], nilled: %i[start_date duration], expected: {} },
        { initial: %i[                              ], nilled: %i[start_date duration], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[due_date duration], expected: { change: :start_date } },
        { initial: %i[start_date                    ], set: %i[due_date duration], expected: { change: :start_date } },
        { initial: %i[            due_date          ], set: %i[due_date duration], expected: { change: :start_date } },
        { initial: %i[                      duration], set: %i[due_date duration], expected: { change: :start_date } },
        { initial: %i[                              ], set: %i[due_date duration], expected: { change: :start_date } },

        { initial: %i[start_date  due_date  duration], set: %i[due_date], nilled: %i[duration], expected: { nilify: :start_date } },
        { initial: %i[start_date                    ], set: %i[due_date], nilled: %i[duration], expected: { nilify: :start_date, same: :duration } },
        { initial: %i[            due_date          ], set: %i[due_date], nilled: %i[duration], expected: {} },
        { initial: %i[                      duration], set: %i[due_date], nilled: %i[duration], expected: {} },
        { initial: %i[                              ], set: %i[due_date], nilled: %i[duration], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[duration], nilled: %i[due_date], expected: { nilify: :start_date } },
        { initial: %i[start_date                    ], set: %i[duration], nilled: %i[due_date], expected: { nilify: :start_date, same: :due_date } },
        { initial: %i[            due_date          ], set: %i[duration], nilled: %i[due_date], expected: {} },
        { initial: %i[                      duration], set: %i[duration], nilled: %i[due_date], expected: {} },
        { initial: %i[                              ], set: %i[duration], nilled: %i[due_date], expected: {} },

        { initial: %i[start_date  due_date  duration], nilled: %i[due_date duration], expected: {} },
        { initial: %i[start_date                    ], nilled: %i[due_date duration], expected: {} },
        { initial: %i[            due_date          ], nilled: %i[due_date duration], expected: {} },
        { initial: %i[                      duration], nilled: %i[due_date duration], expected: {} },
        { initial: %i[                              ], nilled: %i[due_date duration], expected: {} },

        { initial: %i[start_date  due_date  duration], set: %i[start_date due_date duration], expected: {} },
        { initial: %i[start_date                    ], set: %i[start_date due_date duration], expected: {} },
        { initial: %i[            due_date          ], set: %i[start_date due_date duration], expected: {} },
        { initial: %i[                      duration], set: %i[start_date due_date duration], expected: {} },
        { initial: %i[                              ], set: %i[start_date due_date duration], expected: {} }
      ]
      # rubocop:enable Layout/ExtraSpacing, Layout/SpaceInsideArrayPercentLiteral, Layout/SpaceInsidePercentLiteralDelimiters, Layout/LineLength

      let(:initial_attributes) { { start_date: today, due_date: today + 49.days, duration: 50 } }
      let(:set_attributes) { { start_date: today + 10.days, due_date: today + 12.days, duration: 3 } }
      let(:nil_attributes) { { start_date: nil, due_date: nil, duration: nil } }

      all_possible_scenarios.each do |scenario|
        initial = scenario[:initial]
        set = scenario[:set] || []
        nilled = scenario[:nilled] || []
        expected = scenario[:expected]
        expected_change = expected[:change]
        expected_same = expected[:same]
        expected_nilify = expected[:nilify]
        unchanged = %i[start_date due_date duration] - set - nilled - expected.values + [expected_same].compact

        context_description = []
        context_description << "with initial values for #{initial.inspect}" if initial.any?
        context_description << "without any initial values" if initial.none?
        context_description << "with #{set.inspect} set" if set.any?
        context_description << "with #{nilled.inspect} nilled" if nilled.any?
        context_description << "without any attributes set" if set.none? && nilled.none?

        context context_description.join(", and ") do
          let(:work_package_attributes) { nil_attributes.merge(initial_attributes.slice(*initial)) }
          let(:work_package) { build_stubbed(:work_package, work_package_attributes) }
          let(:call_attributes) { nil_attributes.slice(*nilled).merge(set_attributes.slice(*set)) }

          it_behaves_like "service call" do
            if expected_change
              it "changes #{expected_change.inspect}" do
                expect { subject }
                  .to change(work_package, expected_change)
              end
            end

            if expected_nilify
              it "sets #{expected_nilify.inspect} to nil" do
                expect { subject }
                  .to change(work_package, expected_nilify).to(nil)
              end
            end

            if unchanged.any?
              it "does not change #{unchanged.map(&:inspect).join(' and ')}" do
                expect { subject }
                  .not_to change { work_package.slice(*unchanged) }
              end
            end
          end
        end
      end
    end

    context "with non-working days" do
      shared_let(:working_days) { week_with_saturday_and_sunday_as_weekend }
      let(:monday) { Time.zone.today.beginning_of_week }
      let(:tuesday) { monday + 1.day }
      let(:wednesday) { monday + 2.days }
      let(:friday) { monday + 4.days }
      let(:sunday) { monday + 6.days }
      let(:next_monday) { monday + 7.days }
      let(:next_tuesday) { monday + 8.days }

      context "when start date changes" do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday)
        end
        let(:call_attributes) { { start_date: wednesday } }

        it_behaves_like "service call" do
          it "updates the duration without including non-working days" do
            expect { subject }
              .to change(work_package, :duration)
              .from(6)
              .to(4)
          end
        end
      end

      context "when due date changes" do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday)
        end
        let(:call_attributes) { { due_date: monday + 14.days } }

        it_behaves_like "service call" do
          it "updates the duration without including non-working days" do
            expect { subject }
              .to change(work_package, :duration)
              .from(6)
              .to(11)
          end
        end
      end

      context "when duration changes" do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday)
        end
        let(:call_attributes) { { duration: "13" } }

        it_behaves_like "service call" do
          it "updates the due date from start date and duration and skips the non-working days" do
            expect { subject }
              .to change(work_package, :due_date)
              .from(next_monday)
              .to(monday + 16.days)
          end
        end
      end

      context "when duration and end_date both change" do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday)
        end
        let(:call_attributes) { { due_date: next_tuesday, duration: 4 } }

        it_behaves_like "service call" do
          it "updates the start date and skips the non-working days" do
            expect { subject }
              .to change(work_package, :start_date)
              .from(monday)
              .to(monday.next_occurring(:thursday))
          end
        end
      end

      context 'when "ignore non-working days" is switched to true' do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday, ignore_non_working_days: false)
        end
        let(:call_attributes) { { ignore_non_working_days: true } }

        it_behaves_like "service call" do
          it "updates the due date from start date and duration to include the non-working days" do
            # start_date and duration are checked too to ensure they did not change
            expect { subject }
              .to change { work_package.slice(:start_date, :due_date, :duration) }
              .from(start_date: monday, due_date: next_monday, duration: 6)
              .to(start_date: monday, due_date: next_monday - 2.days, duration: 6)
          end
        end
      end

      context 'when "ignore non-working days" is switched to false' do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday, ignore_non_working_days: true)
        end
        let(:call_attributes) { { ignore_non_working_days: false } }

        it_behaves_like "service call" do
          it "updates the due date from start date and duration to skip the non-working days" do
            # start_date and duration are checked too to ensure they did not change
            expect { subject }
              .to change { work_package.slice(:start_date, :due_date, :duration) }
              .from(start_date: monday, due_date: next_monday, duration: 8)
              .to(start_date: monday, due_date: next_monday + 2.days, duration: 8)
          end
        end
      end

      context 'when "ignore non-working days" is switched to false and "start date" is on a non-working day' do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday - 1.day, due_date: friday, ignore_non_working_days: true)
        end
        let(:call_attributes) { { ignore_non_working_days: false } }

        it_behaves_like "service call" do
          it "updates the start date to be on next working day, and due date to accommodate duration" do
            expect { subject }
              .to change { work_package.slice(:start_date, :due_date, :duration) }
              .from(start_date: monday - 1.day, due_date: friday, duration: 6)
              .to(start_date: monday, due_date: next_monday, duration: 6)
          end
        end

        context "with a new work package" do
          let(:work_package) do
            build(:work_package, start_date: monday - 1.day, due_date: friday, ignore_non_working_days: true)
          end
          let(:call_attributes) { { ignore_non_working_days: false, duration: 6 } }

          it_behaves_like "service call" do
            it "updates the start date to be on next working day, and due date to accommodate duration" do
              expect { subject }
                .to change { work_package.slice(:start_date, :due_date, :duration) }
                .from(start_date: monday - 1.day, due_date: friday, duration: 6)
                .to(start_date: monday, due_date: next_monday, duration: 6)
            end
          end
        end
      end

      context 'when "ignore non-working days" is switched to false and "finish date" is on a non-working day' do
        let(:work_package) do
          build_stubbed(:work_package, start_date: nil, due_date: sunday, ignore_non_working_days: true)
        end
        let(:call_attributes) { { ignore_non_working_days: false } }

        it_behaves_like "service call" do
          it "updates the finish date to be on next working day" do
            expect { subject }
              .to change { work_package.slice(:start_date, :due_date, :duration) }
              .from(start_date: nil, due_date: sunday, duration: nil)
              .to(start_date: nil, due_date: next_monday, duration: nil)
          end
        end
      end

      context 'when "ignore non-working days" is changed AND "finish date" is cleared' do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday, ignore_non_working_days: true)
        end
        let(:call_attributes) { { ignore_non_working_days: false, due_date: nil } }

        it_behaves_like "service call" do
          it "does not recompute the due date and nilifies the due date and the duration instead" do
            expect { subject }
              .to change { work_package.slice(:start_date, :due_date, :duration) }
              .from(start_date: monday, due_date: next_monday, duration: 8)
              .to(start_date: monday, due_date: nil, duration: nil)
          end
        end
      end

      context 'when "ignore non-working days" is changed AND "finish date" is set to another date' do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday, ignore_non_working_days: true)
        end
        let(:call_attributes) { { due_date: wednesday, ignore_non_working_days: false } }

        it_behaves_like "service call" do
          it "updates the start date from due date and duration to skip the non-working days" do
            expect { subject }
              .to change { work_package.slice(:start_date, :due_date, :duration) }
              .from(start_date: monday, due_date: next_monday, duration: 8)
              .to(start_date: wednesday - 9.days, due_date: wednesday, duration: 8)
          end
        end
      end

      context 'when "ignore non-working days" is changed AND "start date" and "finish date" are set to other dates' do
        let(:work_package) do
          build_stubbed(:work_package, start_date: monday, due_date: next_monday, ignore_non_working_days: true)
        end
        let(:call_attributes) { { start_date: friday, due_date: next_tuesday, ignore_non_working_days: false } }

        it_behaves_like "service call" do
          it "updates the duration from start date and due date" do
            expect { subject }
              .to change { work_package.slice(:start_date, :due_date, :duration) }
              .from(start_date: monday, due_date: next_monday, duration: 8)
              .to(start_date: friday, due_date: next_tuesday, duration: 3)
          end
        end
      end
    end
  end

  context "for priority" do
    let(:default_priority) { build_stubbed(:priority) }
    let(:other_priority) { build_stubbed(:priority) }

    before do
      scope = class_double(IssuePriority)

      allow(IssuePriority)
        .to receive(:active)
              .and_return(scope)
      allow(scope)
        .to receive(:default)
              .and_return(default_priority)
    end

    context "with no value set before for a new work package" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { {} }
      let(:work_package) { new_work_package }

      before do
        work_package.priority = nil
      end

      it_behaves_like "service call" do
        it "sets the default priority" do
          subject

          expect(work_package.priority)
            .to eql default_priority
        end
      end
    end

    context "when updating priority before calling the service" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { { priority: other_priority } }

      before do
        work_package.attributes = expected_attributes
      end

      it_behaves_like "service call"
    end

    context "when updating priority via attributes" do
      let(:call_attributes) { expected_attributes }
      let(:expected_attributes) { { priority: other_priority } }

      it_behaves_like "service call"
    end
  end

  context "when switching the type" do
    let(:target_type) { build_stubbed(:type, is_milestone:) }
    let(:work_package) do
      build_stubbed(:work_package, start_date: Time.zone.today - 6.days, due_date: Time.zone.today)
    end

    context "to a non-milestone type" do
      let(:is_milestone) { false }

      it "keeps the start date" do
        instance.call(type: target_type)

        expect(work_package.start_date)
          .to eql Time.zone.today - 6.days
      end

      it "keeps the due date" do
        instance.call(type: target_type)

        expect(work_package.due_date)
          .to eql Time.zone.today
      end

      it "keeps duration" do
        instance.call(type: target_type)

        expect(work_package.duration).to be 7
      end
    end

    context "to a milestone type" do
      let(:is_milestone) { true }

      context "with both dates set" do
        it "sets the start date to the due date" do
          instance.call(type: target_type)

          expect(work_package.start_date).to eq work_package.due_date
        end

        it "keeps the due date" do
          instance.call(type: target_type)

          expect(work_package.due_date).to eql Time.zone.today
        end

        it "sets the duration to 1 (to be changed to 0 later on)" do
          instance.call(type: target_type)

          expect(work_package.duration).to eq 1
        end
      end

      context "with only the start date set" do
        let(:work_package) do
          build_stubbed(:work_package, start_date: Time.zone.today - 6.days)
        end

        it "keeps the start date" do
          instance.call(type: target_type)

          expect(work_package.start_date).to eql Time.zone.today - 6.days
        end

        it "set the due date to the start date" do
          instance.call(type: target_type)

          expect(work_package.due_date).to eql work_package.start_date
        end

        it "keeps the duration at 1 (to be changed to 0 later on)" do
          instance.call(type: target_type)

          expect(work_package.duration).to eq 1
        end

        context "with a new work package" do
          let(:work_package) do
            build(:work_package, start_date: Time.zone.today - 6.days)
          end
          let(:call_attributes) { { type: target_type, start_date: Time.zone.today - 6.days, due_date: nil, duration: nil } }

          before do
            instance.call(call_attributes)
          end

          it "keeps the start date" do
            expect(work_package.start_date).to eq Time.zone.today - 6.days
          end

          it "set the due date to the start date" do
            expect(work_package.due_date).to eq work_package.start_date
          end

          it "keeps the duration at 1 (to be changed to 0 later on)" do
            expect(work_package.duration).to eq 1
          end
        end
      end
    end
  end

  context "when switching the project" do
    let(:new_project) { build_stubbed(:project) }
    let(:version) { build_stubbed(:version) }
    let(:category) { build_stubbed(:category) }
    let(:new_category) { build_stubbed(:category, name: category.name) }
    let(:new_statuses) { [work_package.status] }
    let(:new_versions) { [] }
    let(:type) { work_package.type }
    let(:new_types) { [type] }
    let(:default_type) { build_stubbed(:type_standard) }
    let(:other_type) { build_stubbed(:type) }
    let(:yet_another_type) { build_stubbed(:type) }

    let(:call_attributes) { {} }
    let(:new_project_categories) do
      instance_double(ActiveRecord::Relation).tap do |categories_stub|
        allow(new_project)
          .to receive(:categories)
                .and_return(categories_stub)
      end
    end

    before do
      without_partial_double_verification do
        allow(new_project_categories)
        .to receive(:find_by)
              .with(name: category.name)
              .and_return nil
        allow(new_project)
          .to receive_messages(shared_versions: new_versions, types: new_types)
        allow(new_types)
          .to receive(:order)
                .with(:position)
                .and_return(new_types)
      end
    end

    shared_examples_for "updating the project" do
      context "for version" do
        before do
          work_package.version = version
        end

        context "when not shared in new project" do
          it "sets to nil" do
            subject

            expect(work_package.version)
              .to be_nil
          end
        end

        context "when shared in the new project" do
          let(:new_versions) { [version] }

          it "keeps the version" do
            subject

            expect(work_package.version)
              .to eql version
          end
        end
      end

      context "for category" do
        before do
          work_package.category = category
        end

        context "when no category of same name in new project" do
          it "sets to nil" do
            subject

            expect(work_package.category)
              .to be_nil
          end
        end

        context "when category of same name in new project" do
          before do
            allow(new_project_categories)
              .to receive(:find_by)
                    .with(name: category.name)
                    .and_return new_category
          end

          it "uses the equally named category" do
            subject

            expect(work_package.category)
              .to eql new_category
          end

          it "adds change to system changes" do
            subject

            expect(work_package.changed_by_system["category_id"])
              .to eql [nil, new_category.id]
          end
        end
      end

      context "for type" do
        context "when the work package has a type already set" do
          let(:work_package) do
            build_stubbed(:work_package, project:, type: initial_type)
          end

          it "leaves the type" do
            subject

            expect(work_package.type)
              .to eql initial_type
          end
        end

        context "when the work package has no type set" do
          let(:work_package) do
            build_stubbed(:work_package, project:, type: nil)
          end

          let(:new_types) { [other_type] }

          it "uses the first type (by position)" do
            subject

            expect(work_package.type)
              .to eql other_type
          end

          it "adds change to system changes" do
            subject

            expect(work_package.changed_by_system["type_id"])
              .to eql [nil, other_type.id]
          end
        end

        context "and also setting a new type via attributes" do
          let(:new_types) { [yet_another_type] }
          let(:expected_attributes) { { project: new_project, type: yet_another_type } }

          it "sets the desired type" do
            subject

            expect(work_package.type)
              .to eql yet_another_type
          end

          it "does not set the change to system changes" do
            subject

            expect(work_package.changed_by_system)
              .not_to include("type_id")
          end
        end
      end

      context "for parent" do
        let(:parent_work_package) { build_stubbed(:work_package, project:) }
        let(:work_package) do
          build_stubbed(:work_package, project:, type: initial_type, parent: parent_work_package)
        end

        context "with cross project relations allowed", with_settings: { cross_project_work_package_relations: true } do
          it "keeps the parent" do
            expect(subject)
              .to be_success

            expect(work_package.parent)
              .to eql(parent_work_package)
          end
        end

        context "with cross project relations disabled", with_settings: { cross_project_work_package_relations: false } do
          it "deletes the parent" do
            expect(subject)
              .to be_success

            expect(work_package.parent)
              .to be_nil
          end
        end
      end
    end

    context "when updating project before calling the service" do
      let(:call_attributes) { {} }
      let(:expected_attributes) { { project: new_project } }

      before do
        work_package.attributes = expected_attributes
      end

      it_behaves_like "service call" do
        it_behaves_like "updating the project"
      end
    end

    context "when updating project via attributes" do
      let(:call_attributes) { expected_attributes }
      let(:expected_attributes) { { project: new_project } }

      it_behaves_like "service call" do
        it_behaves_like "updating the project"
      end
    end
  end

  context "for custom fields" do
    subject { instance.call(call_attributes) }

    context "for non existing fields" do
      let(:call_attributes) { { custom_field_891: "1" } }

      before do
        subject
      end

      it "is successful" do
        expect(subject).to be_success
      end
    end
  end

  context "when switching back to automatic scheduling" do
    let(:work_package) do
      wp = build_stubbed(:work_package,
                         project:,
                         ignore_non_working_days: true,
                         schedule_manually: true,
                         start_date: Time.zone.today,
                         due_date: Time.zone.today + 5.days)
      wp.type = build_stubbed(:type)
      wp.clear_changes_information

      allow(wp)
        .to receive(:soonest_start)
              .and_return(soonest_start)

      wp
    end
    let(:call_attributes) { { schedule_manually: false } }
    let(:expected_attributes) { {} }
    let(:soonest_start) { Time.zone.today + 1.day }

    context "when the soonest start date is later than the current start date" do
      let(:soonest_start) { Time.zone.today + 3.days }

      it_behaves_like "service call" do
        it "sets the start date to the soonest possible start date" do
          subject

          expect(work_package.start_date).to eql(Time.zone.today + 3.days)
          expect(work_package.due_date).to eql(Time.zone.today + 8.days)
        end
      end
    end

    context "when the soonest start date is a non-working day" do
      shared_let(:working_days) { week_with_saturday_and_sunday_as_weekend }
      let(:saturday) { Time.zone.today.beginning_of_week.next_occurring(:saturday) }
      let(:next_monday) { saturday.next_occurring(:monday) }
      let(:soonest_start) { saturday }

      before do
        work_package.ignore_non_working_days = false
      end

      it_behaves_like "service call" do
        it "sets the start date to the soonest possible start date being a working day" do
          subject

          expect(work_package).to have_attributes(
            start_date: next_monday,
            due_date: next_monday + 7.days
          )
        end
      end
    end

    context "when the soonest start date is before the current start date" do
      let(:soonest_start) { Time.zone.today - 3.days }

      it_behaves_like "service call" do
        it "sets the start date to the soonest possible start date" do
          subject

          expect(work_package.start_date).to eql(soonest_start)
          expect(work_package.due_date).to eql(Time.zone.today + 2.days)
        end
      end
    end

    context "when the soonest start date is nil" do
      let(:soonest_start) { nil }

      it_behaves_like "service call" do
        it "sets the start date to the soonest possible start date" do
          subject

          expect(work_package.start_date).to eql(Time.zone.today)
          expect(work_package.due_date).to eql(Time.zone.today + 5.days)
        end
      end
    end

    context "when the work package also has a child" do
      let(:child) do
        build_stubbed(:work_package,
                      start_date: child_start_date,
                      due_date: child_due_date)
      end
      let(:child_start_date) { Time.zone.today + 2.days }
      let(:child_due_date) { Time.zone.today + 10.days }

      before do
        allow(work_package)
          .to receive(:children)
                .and_return([child])
      end

      context "when the child`s start date is after soonest_start" do
        it_behaves_like "service call" do
          it "sets the dates to the child dates" do
            subject

            expect(work_package.start_date).to eql(Time.zone.today + 2.days)
            expect(work_package.due_date).to eql(Time.zone.today + 10.days)
          end
        end
      end

      context "when the child`s start date is before soonest_start" do
        let(:soonest_start) { Time.zone.today + 3.days }

        it_behaves_like "service call" do
          it "sets the dates to soonest date and to the duration of the child" do
            subject

            expect(work_package.start_date).to eql(Time.zone.today + 3.days)
            expect(work_package.due_date).to eql(Time.zone.today + 11.days)
          end
        end
      end
    end
  end
end
