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
require_relative "../shared_expectations"

RSpec.describe CustomActions::Actions::DoneRatio do
  let(:key) { :done_ratio }
  let(:type) { :integer_property }

  it_behaves_like "base custom action" do
    describe "#apply" do
      let(:work_package) { build_stubbed(:work_package) }

      it "sets the done_ratio to the action's value" do
        instance.values = [95]

        instance.apply(work_package)

        expect(work_package.done_ratio)
          .to be 95
      end
    end

    describe "#multi_value?" do
      it "is false" do
        expect(instance)
          .not_to be_multi_value
      end
    end

    describe "validate" do
      let(:errors) do
        build_stubbed(:custom_action).errors
      end

      it "is valid for values between 0 and 100" do
        instance.values = [50]

        instance.validate(errors)

        expect(errors)
          .to be_empty
      end

      it "is invalid for values larger than 100" do
        instance.values = [101]

        instance.validate(errors)

        expect(errors.symbols_for(:actions))
          .to include(:smaller_than_or_equal_to)
      end

      it "is invalid for values smaller than 0" do
        instance.values = [-1]

        instance.validate(errors)

        expect(errors.symbols_for(:actions))
          .to include(:greater_than_or_equal_to)
      end
    end

    describe ".all" do
      context "in status-based progress calculation mode", with_settings: { work_package_done_ratio: "status" } do
        it "is empty" do
          expect(described_class.all)
            .to be_empty
        end
      end
    end
  end
end
