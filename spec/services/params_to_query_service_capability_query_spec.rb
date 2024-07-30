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

RSpec.describe ParamsToQueryService, "capability query" do
  # This spec does currently not cover the whole functionality.
  let(:user) { build_stubbed(:admin) }
  let(:model) { Capability }
  let(:params) { {} }
  let(:instance) { described_class.new(model, user) }
  let(:service_call) { instance.call(params) }

  context "for a new query" do
    context "when applying filters" do
      let(:params) do
        { filters: JSON.dump([{ principal: { operator: "=", values: ["4"] } },
                              { context: { operator: "=", values: ["g"] } },
                              { action: { operator: "=", values: ["projects/create"] } }]) }
      end

      it "returns a new query" do
        expect(service_call)
          .to be_a Queries::Capabilities::CapabilityQuery
      end

      it "applies the filters" do
        expect(service_call.filters.map { |f| { field: f.field, operator: f.operator, values: f.values } })
          .to contain_exactly({ field: :principal_id, operator: "=", values: ["4"] },
                              { field: :context, operator: "=", values: ["g"] },
                              { field: :action, operator: "=", values: ["projects/create"] })
      end
    end
  end
end
