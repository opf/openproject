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

RSpec.describe CustomActions::Actions::EstimatedHours do
  let(:key) { :estimated_hours }
  let(:type) { :float_property }
  let(:value) { 1.0 }

  it_behaves_like "base custom action" do
    describe "#apply" do
      let(:work_package) { build_stubbed(:work_package) }

      it "sets the done_ratio to the action's value" do
        instance.values = [95.56]

        instance.apply(work_package)

        expect(work_package.estimated_hours)
          .to be 95.56
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

      it "is valid for values equal to or greater than 0" do
        instance.values = [50]

        instance.validate(errors)

        expect(errors)
          .to be_empty
      end

      it "is invalid for values smaller than 0" do
        instance.values = [-0.00001]

        instance.validate(errors)

        expect(errors.symbols_for(:actions))
          .to include(:greater_than_or_equal_to)
      end
    end
  end
end
