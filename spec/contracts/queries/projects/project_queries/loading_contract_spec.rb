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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Queries::Projects::ProjectQueries::LoadingContract do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }
  let(:query_user) { current_user }
  let(:query_filters) { [[:active, "=", "t"]] }
  let(:query_orders) { [%w[name asc]] }
  let(:query_columns) { ["name", "public"] }
  let(:query) do
    ProjectQuery.new do |query|
      query_filters.each do |key, operator, values|
        query.where(key, operator, values)
      end

      query.order(query_orders)
      query.select(*query_columns)
    end
  end
  let(:contract) { described_class.new(query, current_user) }

  describe "validation" do
    it_behaves_like "contract is valid"
  end
end
