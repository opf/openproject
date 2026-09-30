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

RSpec.describe PermittedParams do
  let(:user) { build(:user) }

  shared_examples_for "allows params" do
    let(:params_key) { defined?(hash_key) ? hash_key : attribute }
    let(:params) do
      nested_params = if defined?(nested_key)
                        { nested_key => hash }
                      else
                        hash
                      end

      ac_params = if defined?(flat) && flat
                    nested_params
                  else
                    { params_key => nested_params }
                  end

      ActionController::Parameters.new(ac_params)
    end

    subject { PermittedParams.new(params, user).send(attribute).to_h }

    it do
      expected = defined?(allowed_params) ? allowed_params : hash
      expect(subject).to eq(expected)
    end
  end

  describe "budget" do
    let(:attribute) { :budget }

    describe "#subject" do
      let(:hash) { { "subject" => "subject_test" } }

      it_behaves_like "allows params"
    end

    describe "#description" do
      let(:hash) { { "description" => "description_test" } }

      it_behaves_like "allows params"
    end

    describe "#fixed_date" do
      let(:hash) { { "fixed_date" => "2017-03-01" } }

      it_behaves_like "allows params"
    end

    describe "#base_amount" do
      let(:hash) { { "base_amount" => "250000.00" } }

      it_behaves_like "allows params"
    end

    describe "#project_id" do
      let(:hash) { { "project_id" => 42 } }

      it_behaves_like "allows params" do
        let(:allowed_params) { {} }
      end
    end

    describe "#existing_material_budget_item" do
      let(:hash) do
        { "existing_material_budget_item_attributes" => { "1" => {
          "units" => "100.0",
          "cost_type_id" => "1",
          "comments" => "First package",
          "amount" => "5,000.00"
        } } }
      end

      it_behaves_like "allows params"
    end

    describe "#new_material_budget_item" do
      let(:hash) do
        { "new_material_budget_item_attributes" => { "1" => {
          "units" => "20",
          "cost_type_id" => "2",
          "comments" => "Macbooks",
          "amount" => "52,000.00"
        } } }
      end

      it_behaves_like "allows params"
    end

    describe "#existing_labor_budget_item" do
      let(:hash) do
        { "existing_labor_budget_item_attributes" => { "1" => {
          "hours" => "20.0",
          "user_id" => "1",
          "comments" => "App Setup",
          "amount" => "2000.00"
        } } }
      end

      it_behaves_like "allows params"
    end

    describe "#new_labor_budget_item" do
      let(:hash) do
        { "new_labor_budget_item_attributes" => { "1" => {
          "hours" => "5.0",
          "user_id" => "2",
          "comments" => "Overhead",
          "amount" => "400"
        } } }
      end

      it_behaves_like "allows params"
    end
  end
end
