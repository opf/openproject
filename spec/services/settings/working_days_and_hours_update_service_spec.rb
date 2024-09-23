#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require "spec_helper"
require_relative "shared/shared_call_examples"

RSpec.describe Settings::WorkingDaysAndHoursUpdateService do
  let(:instance) do
    described_class.new(user:)
  end
  let(:user) { build_stubbed(:user) }
  let(:contract) do
    instance_double(Settings::UpdateContract,
                    validate: contract_success,
                    errors: instance_double(ActiveModel::Error))
  end
  let(:contract_success) { true }
  let(:params_contract) do
    instance_double(Settings::WorkingDaysAndHoursParamsContract,
                    valid?: params_contract_success,
                    errors: instance_double(ActiveModel::Error))
  end
  let(:params_contract_success) { true }
  let(:setting_name) { :a_setting_name }
  let(:new_setting_value) { "a_new_setting_value" }
  let(:previous_setting_value) { "the_previous_setting_value" }
  let(:setting_params) { { setting_name => new_setting_value } }
  let(:non_working_days_params) { {} }
  let(:params) { setting_params.merge(non_working_days: non_working_days_params) }

  before do
    # stub a setting definition
    allow(Setting)
      .to receive(:[])
            .and_call_original
    allow(Setting)
      .to receive(:[]).with(setting_name)
                      .and_return(previous_setting_value)
    allow(Setting)
      .to receive(:[]=)

    # stub contract
    allow(Settings::UpdateContract)
      .to receive(:new)
            .and_return(contract)
    allow(Settings::WorkingDaysAndHoursParamsContract)
      .to receive(:new)
            .and_return(params_contract)
  end

  describe "#call" do
    subject { instance.call(params) }

    shared_examples "successful working days settings call" do
      include_examples "successful call"

      it "calls the WorkPackages::ApplyWorkingDaysChangeJob" do
        previous_working_days = Setting[:working_days]
        previous_non_working_days = NonWorkingDay.pluck(:date)

        allow(WorkPackages::ApplyWorkingDaysChangeJob).to receive(:perform_later)

        subject

        expect(WorkPackages::ApplyWorkingDaysChangeJob)
          .to have_received(:perform_later)
                .with(user_id: user.id, previous_working_days:, previous_non_working_days:)
      end
    end

    shared_examples "unsuccessful working days settings call" do
      include_examples "unsuccessful call"

      it "does not persists the non working days" do
        expect { subject }.not_to change(NonWorkingDay, :count)
      end

      it "does not calls the WorkPackages::ApplyWorkingDaysChangeJob" do
        allow(WorkPackages::ApplyWorkingDaysChangeJob).to receive(:perform_later)
        subject

        expect(WorkPackages::ApplyWorkingDaysChangeJob).not_to have_received(:perform_later)
      end
    end

    include_examples "successful working days settings call"

    context "when non working days are present" do
      let!(:existing_nwd) { create(:non_working_day, name: "Existing NWD") }
      let!(:nwd_to_delete) { create(:non_working_day, name: "NWD to delete") }
      let(:non_working_days_params) do
        [
          { "name" => "Christmas Eve", "date" => "2022-12-24" },
          { "name" => "NYE", "date" => "2022-12-31" },
          { "id" => existing_nwd.id },
          { "id" => nwd_to_delete.id, "_destroy" => true }
        ]
      end

      include_examples "successful working days settings call"

      it "persists (create/delete) the non working days" do
        expect { subject }.to change(NonWorkingDay, :count).by(1)

        expect { nwd_to_delete.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect(NonWorkingDay.all).to contain_exactly(
          have_attributes(name: "Christmas Eve", date: Date.parse("2022-12-24")),
          have_attributes(name: "NYE", date: Date.parse("2022-12-31")),
          have_attributes(existing_nwd.slice(:id, :name, :date))
        )
      end

      context "when there are duplicates" do
        context "with both within the params" do
          let(:non_working_days_params) do
            [
              { "name" => "Christmas Eve", "date" => "2022-12-24" },
              { "name" => "Christmas Eve", "date" => "2022-12-24" }
            ]
          end

          include_examples "unsuccessful working days settings call"
        end

        context "with one saved in the database" do
          let(:non_working_days_params) do
            [existing_nwd.slice(:name, :date)]
          end

          include_examples "unsuccessful working days settings call"

          context "when deleting and re-creating the duplicate non-working day" do
            let(:non_working_days_params) do
              [
                nwd_to_delete.slice(:id, :name, :date).merge("_destroy" => true),
                nwd_to_delete.slice(:name, :date)
              ]
            end

            include_examples "successful working days settings call"

            it "persists (create/delete) the non working days" do
              expect { subject }.not_to change(NonWorkingDay, :count)
              expect { nwd_to_delete.reload }.to raise_error(ActiveRecord::RecordNotFound)

              # The nwd_to_delete is being re-created after the deletion.
              expect(NonWorkingDay.all).to contain_exactly(
                have_attributes(existing_nwd.slice(:name, :date)),
                have_attributes(nwd_to_delete.slice(:name, :date))
              )
            end
          end

          context "with duplicate params when deleting and re-creating non-working days" do
            let(:non_working_days_params) do
              [
                existing_nwd.slice(:id, :name, :date).merge("_destroy" => true),
                existing_nwd.slice(:name, :date),
                existing_nwd.slice(:name, :date)
              ]
            end

            include_examples "unsuccessful working days settings call"

            it "returns the unchanged results including the ones marked for destruction" do
              result = subject.result

              expect(result).to contain_exactly(
                have_attributes(existing_nwd.slice(:id, :name, :date)),
                have_attributes(existing_nwd.slice(:name, :date).merge(id: nil)),
                have_attributes(existing_nwd.slice(:name, :date).merge(id: nil))
              )

              expect(result.find { |r| r.id == existing_nwd.id }).to be_marked_for_destruction
            end
          end
        end
      end
    end

    context "when the params contract is not successfully validated" do
      let(:params_contract_success) { false }

      include_examples "unsuccessful working days settings call"
    end

    context "when the contract is not successfully validated" do
      let(:contract_success) { false }

      include_examples "unsuccessful working days settings call"

      context "when non working days are present" do
        let(:non_working_days_params) do
          [
            { "name" => "Christmas Eve", "date" => "2022-12-24" },
            { "name" => "NYE", "date" => "2022-12-31" }
          ]
        end

        include_examples "unsuccessful working days settings call"
      end
    end
  end
end
