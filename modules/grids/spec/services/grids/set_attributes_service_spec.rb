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

RSpec.describe Grids::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = double("contract_class")

    allow(contract)
      .to receive(:new)
      .with(grid, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    double("contract_instance", validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double("contract_errors")
  end
  let(:grid_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model: grid,
                        contract_class:)
  end
  let(:call_attributes) { {} }
  let(:grid_class) { Grids::Grid }
  let(:grid) do
    build_stubbed(grid_class.name.demodulize.underscore.to_sym, widgets: [])
  end

  describe "call" do
    let(:call_attributes) do
      {
        column_count: 6
      }
    end

    before do
      expect(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    subject { instance.call(call_attributes) }

    it "is successful" do
      expect(subject.success?).to be_truthy
    end

    it "sets the attributes" do
      subject

      expect(grid.attributes.slice(*grid.changed).symbolize_keys)
        .to eql call_attributes
    end

    it "does not persist the grid" do
      expect(grid)
        .not_to receive(:save)

      subject
    end

    context "with additional widgets" do
      let(:widgets) do
        [
          build_stubbed(:grid_widget,
                        identifier: "work_packages_assigned",
                        start_row: 3,
                        end_row: 5,
                        start_column: 1,
                        end_column: 3)
        ]
      end

      let(:call_attributes) do
        {
          widgets:
        }
      end

      before do
        subject
      end

      it "adds the new widgets" do
        expect(grid.widgets.length)
          .to be 1
      end

      it "does not persist the new widget" do
        expect(grid.widgets[0])
          .to be_new_record
      end

      it "applies the provided values" do
        expect(grid.widgets[0].attributes.except("id"))
          .to eql widgets[0].attributes.except("id").merge("grid_id" => grid.id)
      end

      context "with the widget not being allowed" do
        before do
          allow(Grids::Configuration)
            .to receive(:allowed_widget?)
            .with(grid, "work_packages_assigned", user, nil)
            .and_return(false)
        end

        context "with the grid being a new record" do
          let(:existing_widgets) do
            [
              build(:grid_widget,
                    identifier: "work_packages_assigned",
                    start_row: 3,
                    end_row: 5,
                    start_column: 1,
                    end_column: 3)
            ]
          end

          let(:grid) do
            build(
              :grid,
              widgets: existing_widgets
            )
          end

          it "leaves the prohibited widget" do
            expect(grid.widgets.length)
              .to be 1
          end
        end

        context "with the grid not being a new record" do
          it "leaves the prohibited widget" do
            expect(grid.widgets.length)
              .to be 1
          end
        end
      end
    end

    context "with empty widget params" do
      let(:existing_widgets) do
        [
          build_stubbed(:grid_widget,
                        identifier: "work_packages_assigned",
                        start_row: 3,
                        end_row: 5,
                        start_column: 1,
                        end_column: 3)
        ]
      end
      let(:grid) do
        build_stubbed(
          grid_class.name.demodulize.underscore.to_sym,
          widgets: existing_widgets
        )
      end

      let(:call_attributes) do
        {
          widgets: []
        }
      end

      before do
        subject
      end

      it "does not remove the widget right away" do
        expect(grid.widgets.length)
          .to be 1
      end

      it "marks the widget for destruction" do
        expect(grid.widgets[0])
          .to be_marked_for_destruction
      end

      context "with the widget not being allowed" do
        before do
          allow(Grids::Configuration)
            .to receive(:allowed_widget?)
            .with(grid, "work_packages_assigned", user, nil)
            .and_return(false)
        end

        context "with the grid being a new record" do
          let(:existing_widgets) do
            [
              build(:grid_widget,
                    identifier: "work_packages_assigned",
                    start_row: 3,
                    end_row: 5,
                    start_column: 1,
                    end_column: 3)
            ]
          end

          let(:grid) do
            build(
              :grid,
              widgets: existing_widgets
            )
          end

          it "removes the prohibited widget" do
            expect(grid.widgets)
              .to be_empty
          end
        end

        context "with the grid not being a new record" do
          it "leaves the prohibited widget" do
            expect(grid.widgets.length)
              .to be 1
          end
        end
      end
    end

    context "without widget params" do
      let(:existing_widgets) do
        [
          build_stubbed(:grid_widget,
                        identifier: "work_packages_assigned",
                        start_row: 3,
                        end_row: 5,
                        start_column: 1,
                        end_column: 3)
        ]
      end
      let(:grid) do
        build_stubbed(
          grid_class.name.demodulize.underscore.to_sym,
          widgets: existing_widgets
        )
      end

      let(:call_attributes) { {} }

      before do
        subject
      end

      it "does not remove the widget" do
        expect(grid.widgets.length)
          .to be 1
      end

      it "does not mark the widget for destruction" do
        expect(grid.widgets[0])
          .not_to be_marked_for_destruction
      end

      context "with the widget not being allowed" do
        before do
          allow(Grids::Configuration)
            .to receive(:allowed_widget?)
            .with(grid, "work_packages_assigned", user, nil)
            .and_return(false)
        end

        context "with the grid being a new record" do
          let(:existing_widgets) do
            [
              build(:grid_widget,
                    identifier: "work_packages_assigned",
                    start_row: 3,
                    end_row: 5,
                    start_column: 1,
                    end_column: 3)
            ]
          end

          let(:grid) do
            build(
              :grid,
              widgets: existing_widgets
            )
          end

          it "removes the prohibited widget" do
            expect(grid.widgets)
              .to be_empty
          end
        end

        context "with the grid not being a new record" do
          it "leaves the prohibited widget" do
            expect(grid.widgets.length)
              .to be 1
          end
        end
      end
    end

    context "with updates to an existing widget" do
      let(:widgets) do
        [
          build_stubbed(:grid_widget,
                        id: existing_widgets[0].id,
                        identifier: "work_packages_assigned",
                        start_row: 3,
                        end_row: 5,
                        start_column: 1,
                        end_column: 3)
        ]
      end
      let(:existing_widgets) do
        [
          build_stubbed(:grid_widget,
                        identifier: "work_packages_assigned",
                        start_row: 2,
                        end_row: 5,
                        start_column: 1,
                        end_column: 3)
        ]
      end
      let(:grid) do
        build_stubbed(
          grid_class.name.demodulize.underscore.to_sym,
          widgets: existing_widgets
        )
      end

      let(:call_attributes) { { widgets: } }

      before do
        subject
      end

      it "updates the widget" do
        expect(grid.widgets[0].start_row)
          .to eql widgets[0].start_row
      end

      it "does not persist the changes" do
        expect(grid.widgets[0])
          .to be_changed
      end
    end

    context "with additions and updates to existing widgets" do
      let(:widgets) do
        [
          build_stubbed(:grid_widget,
                        identifier: "work_packages_assigned",
                        start_row: 3,
                        end_row: 5,
                        start_column: 1,
                        end_column: 3),
          build_stubbed(:grid_widget,
                        identifier: "work_packages_watched",
                        start_row: 1,
                        end_row: 2,
                        start_column: 1,
                        end_column: 2),
          build_stubbed(:grid_widget,
                        identifier: "work_packages_calendar",
                        start_row: 2,
                        end_row: 4,
                        start_column: 1,
                        end_column: 2),
          build_stubbed(:grid_widget,
                        identifier: "work_packages_calendar",
                        start_row: 1,
                        end_row: 2,
                        start_column: 4,
                        end_column: 4)
        ]
      end
      let(:existing_widgets) do
        [
          build_stubbed(:grid_widget,
                        identifier: "work_packages_assigned",
                        start_row: 2,
                        end_row: 5,
                        start_column: 1,
                        end_column: 3),
          build_stubbed(:grid_widget,
                        identifier: "work_packages_assigned",
                        start_row: 1,
                        end_row: 2,
                        start_column: 3,
                        end_column: 4),
          build_stubbed(:grid_widget,
                        identifier: "work_packages_calendar",
                        start_row: 1,
                        end_row: 2,
                        start_column: 1,
                        end_column: 2)
        ]
      end
      let(:grid) do
        build_stubbed(
          grid_class.name.demodulize.underscore.to_sym,
          widgets: existing_widgets
        )
      end

      let(:call_attributes) { { widgets: } }

      before do
        subject
      end

      it "updates the widgets but does not persist them" do
        expect(grid.widgets.detect { |w| w.identifier == "work_packages_assigned" && w.changed? }
                 .attributes.slice("start_row", "end_row", "start_colum", "end_column"))
          .to eql("start_row" => 3, "end_row" => 5, "end_column" => 3)

        expect(grid.widgets.detect { |w| w.identifier == "work_packages_calendar" && w.changed? }
                 .attributes.slice("start_row", "end_row", "start_colum", "end_column"))
          .to eql("start_row" => 2, "end_row" => 4, "end_column" => 2)
      end

      it "does not persist the new widgets" do
        expect(grid.widgets.any? { |w| w.identifier == "work_packages_watched" && w.new_record? })
          .to be_truthy

        expect(grid.widgets.any? { |w| w.identifier == "work_packages_calendar" && w.new_record? })
          .to be_truthy
      end

      it "does mark a widget for destruction" do
        expect(grid.widgets.detect(&:marked_for_destruction?).identifier)
          .to eql "work_packages_assigned"
      end
    end
  end
end
