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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

module WorkPackageTypes
  module FormConfigurationGroups
    RSpec.describe CreateService, type: :service, with_ee: %i[edit_attribute_groups] do
      let(:user) { create(:admin) }
      let(:type) { create(:type) }
      let(:relation_query_props) do
        query = create(:query, user:)
        query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
        query.save!

        ::API::V3::Queries::QueryParamsRepresenter
          .new(query)
          .to_json
      end

      subject(:service) { described_class.new(user:, type:) }

      it "creates an attribute group from service params" do
        result = service.call(group_type: "attribute", name: "New Group")

        expect(result).to be_success
        expect(result.result).to be_a(Type::AttributeGroup)
        expect(result.result.key).to eq("New Group")
        expect(type.reload.attribute_groups.first.key).to eq(result.result.key)
      end

      it "creates a query group from service params" do
        result = service.call(group_type: "query", name: "Related work", query_props: relation_query_props)

        expect(result).to be_success
        expect(result.result).to be_a(Type::QueryGroup)
        expect(result.result.key).to eq("Related work")
        expect(result.result.attributes).to be_a(Query)
        expect(type.reload.attribute_groups.first.key).to eq(result.result.key)
      end
    end
  end
end
