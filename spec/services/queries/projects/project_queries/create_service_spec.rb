# -- copyright
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
# ++

require "spec_helper"
require "services/base_services/behaves_like_create_service"

RSpec.describe Queries::Projects::ProjectQueries::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:model_class) { ProjectQuery }
    let(:factory) { :project_query }
  end

  describe "overriding the instance" do
    subject(:result) { described_class.new(from: instance, user:).call(params).result }

    let(:user) { build(:user) }
    let(:params) { { filters: [{ attribute: "active", operator: "=", values: ["f"] }] } }

    context "when overriding initial instance" do
      let(:instance) { build(:project_query).where("public", "=", "t").order(name: :desc) }

      it "returns the instance" do
        expect(result).to eq(instance)
      end

      it "keeps instance value for attribute not passed in params" do
        expect(result).to have_attributes(
          orders: [having_attributes(attribute: :name, direction: :desc)]
        )
      end

      it "sets value for attribute passed in params" do
        expect(result).to have_attributes(
          filters: [having_attributes(name: :active, operator: "=", values: %w[f])]
        )
      end
    end

    context "when not overriding initial instance" do
      let(:instance) { nil }

      it "uses default value for attribute not passed in params" do
        expect(result).to have_attributes(
          orders: [having_attributes(attribute: :lft, direction: :asc)]
        )
      end

      it "sets value for attribute passed in params" do
        expect(result).to have_attributes(
          filters: [having_attributes(name: :active, operator: "=", values: %w[f])]
        )
      end
    end
  end
end
