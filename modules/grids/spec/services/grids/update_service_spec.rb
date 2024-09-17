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

RSpec.describe Grids::UpdateService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    double("contract_class", "<=": true)
  end
  let(:grid_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: grid,
                        contract_class:)
  end
  let(:call_attributes) { {} }
  let(:grid_class) { Grids::Grid }
  let(:set_attributes_success) do
    true
  end
  let(:set_attributes_errors) do
    double("set_attributes_errors")
  end
  let(:set_attributes_result) do
    ServiceResult.new result: grid,
                      success: set_attributes_success,
                      errors: set_attributes_errors
  end
  let!(:grid) do
    grid = build_stubbed(grid_class.name.demodulize.underscore.to_sym)

    allow(grid)
      .to receive(:save)
      .and_return(grid_valid)

    grid
  end
  let!(:set_attributes_service) do
    service = double("set_attributes_service_instance")

    allow(Grids::SetAttributesService)
      .to receive(:new)
      .with(user:,
            model: grid,
            contract_class:,
            contract_options: {})
      .and_return(service)

    allow(service)
      .to receive(:call)
      .and_return(set_attributes_result)

    service
  end

  describe "call" do
    shared_examples_for "service call" do
      subject { instance.call(call_attributes) }

      it "is successful" do
        expect(subject.success?).to be_truthy
      end

      it "returns the result of the SetAttributesService" do
        expect(subject)
          .to eql set_attributes_result
      end

      it "persists the grid" do
        expect(grid)
          .to receive(:save)
          .and_return(grid_valid)

        subject
      end

      context "when the SetAttributeService is unsuccessful" do
        let(:set_attributes_success) { false }

        it "is unsuccessful" do
          expect(subject.success?).to be_falsey
        end

        it "returns the result of the SetAttributesService" do
          expect(subject)
            .to eql set_attributes_result
        end

        it "does not persist the changes" do
          expect(grid)
            .not_to receive(:save)

          subject
        end

        it "exposes the contract's errors" do
          subject

          expect(subject.errors).to eql set_attributes_errors
        end
      end

      context "when the grid is invalid" do
        let(:grid_valid) { false }

        it "is unsuccessful" do
          expect(subject.success?).to be_falsey
        end

        it "exposes the grid's errors" do
          subject

          expect(subject.errors).to eql grid.errors
        end
      end
    end

    context "with parameters" do
      let(:call_attributes) { { row_count: 5 } }

      it_behaves_like "service call"
    end

    context "with parameters only for widgets" do
      let(:call_attributes) { { widgets: [build_stubbed(:grid_widget)] } }

      before do
        allow(set_attributes_service)
          .to receive(:call) do |params|
            grid.widgets.build(params[:widgets].first.attributes)

            allow(grid.widgets.last)
              .to receive(:saved_changes?)
              .and_return(true)

            if set_attributes_success && grid_valid
              expect(grid)
                .to receive(:touch)
            end

            set_attributes_result
          end
      end

      it_behaves_like "service call"
    end
  end
end
