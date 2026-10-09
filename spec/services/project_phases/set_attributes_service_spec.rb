# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ProjectPhases::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = class_double(ProjectPhases::UpdateContract)

    allow(contract)
      .to receive(:new)
      .with(phase, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    instance_double(Projects::UpdateContract, validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    instance_double(ActiveModel::Errors)
  end
  let(:project_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: phase,
                        contract_class:)
  end
  let(:call_attributes) { {} }

  let(:date) { Time.zone.today }
  let(:project) { build_stubbed(:project) }
  let(:phase) { build_stubbed(:project_phase, project:, duration: 0) }

  describe "call" do
    let(:call_attributes) do
      {}
    end

    before do
      allow(project)
        .to receive(:valid?)
        .and_return(project_valid)

      allow(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    subject { instance.call(call_attributes) }

    describe "setting calculated duration" do
      shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

      context "when the date range is complete" do
        let(:call_attributes) { { start_date: date, finish_date: date + 27 } }

        it "sets duration to the number of working days" do
          expect { subject }.to change(phase, :duration).from(0).to(20)
        end
      end

      context "when the date range is incomplete" do
        let(:call_attributes) { { start_date: nil } }

        it "sets duration to nil" do
          expect { subject }.to change(phase, :duration).from(0).to(nil)
        end
      end
    end
  end
end
