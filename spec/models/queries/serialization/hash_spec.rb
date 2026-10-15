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

RSpec.describe Queries::Serialization::Hash do
  current_user { create(:admin) }

  describe "a query without group by support" do
    # This is the pair actually used in production, to hand a ProjectQuery to the
    # export job.
    let(:instance) do
      ProjectQuery.new(name: "Projects").tap do |query|
        query.where("active", "=", ["t"])
        query.order("name" => "asc")
        query.select(:name)
      end
    end

    it "reports no group bys rather than nil" do
      expect(instance.to_hash[:group_bys]).to eq([])
    end

    it "round trips the filters, orders and selects" do
      restored = ProjectQuery.from_hash(instance.to_hash)

      expect(restored.name).to eq("Projects")
      expect(restored.filters.map { |f| [f.name, f.operator, f.values] })
        .to eq(instance.filters.map { |f| [f.name, f.operator, f.values] })
      expect(restored.orders.map { |o| [o.attribute, o.direction] })
        .to eq(instance.orders.map { |o| [o.attribute, o.direction] })
      expect(restored.selects.map(&:attribute)).to eq(instance.selects.map(&:attribute))
    end
  end

  # TODO: cover the group by round trip once a query that serializes to a hash
  # actually registers group bys. Only ProjectQuery and PersistedQuery include
  # this module today, and neither has any - CostReportQuery will be the first.
  # The attributes rather than the group by objects are dumped, so that from_hash
  # can resolve them again.
end
