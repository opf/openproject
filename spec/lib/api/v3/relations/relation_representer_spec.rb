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

RSpec.describe API::V3::Relations::RelationRepresenter do
  let(:user) { build_stubbed(:admin) }

  let(:from) { build_stubbed(:work_package) }
  let(:to) { build_stubbed(:work_package) }

  let(:type) { "follows" }
  let(:description) { "This first" }
  let(:lag) { 3 }

  let(:relation) do
    build_stubbed(:relation,
                  from:,
                  to:,
                  relation_type: type,
                  description:,
                  lag:)
  end

  let(:representer) { described_class.new relation, current_user: user }

  let(:result) do
    {
      "_type" => "Relation",
      "_links" => {
        "self" => {
          "href" => "/api/v3/relations/#{relation.id}"
        },
        "updateImmediately" => {
          "href" => "/api/v3/relations/#{relation.id}",
          "method" => "patch"
        },
        "delete" => {
          "href" => "/api/v3/relations/#{relation.id}",
          "method" => "delete",
          "title" => "Remove relation"
        },
        "from" => {
          "href" => "/api/v3/work_packages/#{from.id}",
          "title" => from.subject
        },
        "to" => {
          "href" => "/api/v3/work_packages/#{to.id}",
          "title" => to.subject
        }
      },
      "id" => relation.id,
      "name" => "follows",
      "type" => "follows",
      "reverseType" => "precedes",
      "description" => description,
      "lag" => lag
    }
  end

  it "serializes the relation correctly" do
    data = JSON.parse representer.to_json

    expect(data).to eq result
  end

  it "deserializes the relation correctly" do
    rep = API::V3::Relations::RelationRepresenter.new OpenStruct.new, current_user: user
    rel = rep.from_json result.except(:id).to_json

    expect(rel.from_id).to eq from.id.to_s
    expect(rel.to_id).to eq to.id.to_s
    expect(rel.lag).to eq lag
    expect(rel.relation_type).to eq type
    expect(rel.description).to eq description
    expect(rel.lag).to eq lag
  end
end
