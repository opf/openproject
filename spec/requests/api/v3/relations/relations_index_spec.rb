#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'GET /api/v3/relations', type: :request do
  let(:user) { FactoryGirl.create :admin }

  let(:work_package) { FactoryGirl.create :work_package }

  let!(:relations) do
    def new_relation(opts = {})
      relation_type = opts.delete(:type)

      relation = FactoryGirl.create :relation, opts.merge(relation_type: relation_type)
      relation.id
    end

    def new_work_package
      FactoryGirl.create :work_package
    end

    [
      new_relation(from: work_package, to: new_work_package, type: 'precedes'),
      new_relation(from: work_package, to: new_work_package, type: 'blocks'),
      new_relation(from: new_work_package, to: work_package, type: 'precedes'),
      new_relation(from: new_work_package, to: new_work_package, type: 'blocks')
    ]
  end

  before do
    login_as user
  end

  describe "filters" do
    def filter_relations(name, operator, values)
      filter = {
        name => {
          "operator" => operator,
          "values" => values
        }
      }
      params = {
        filters: [filter].to_json
      }

      get "/api/v3/relations", params: params

      json = JSON.parse response.body

      Array(Hash(json).dig("_embedded", "elements")).map { |e| e["id"] }
    end

    ##
    # We're testing all cases within one example to save a lot of time.
    # Initializing the relations takes very long (about 2s) and it's unnecessary
    # to repeat that step for every example as we are not mutating anything.
    # This saves about 75% on the runtime (6s vs 24s on this machine) of the spec.
    it 'work' do
      expect(filter_relations("id", "=", [relations[0], relations[2]])).to match_array [relations[0], relations[2]]
      expect(filter_relations("id", "!", [relations[0], relations[2]])).to match_array [relations[1], relations[3]]

      expect(filter_relations("from", "=", [work_package.id])).to match_array [relations[0], relations[1]]
      expect(filter_relations("from", "!", [work_package.id])).to match_array [relations[2], relations[3]]

      expect(filter_relations("to", "=", [work_package.id])).to eq [relations[2]]
      expect(filter_relations("to", "!", [work_package.id])).to match_array [relations[0], relations[1], relations[3]]

      expect(filter_relations("involved", "=", [work_package.id])).to match_array [relations[0], relations[1], relations[2]]
      expect(filter_relations("involved", "!", [work_package.id])).to eq [relations[3]]

      expect(filter_relations("type", "=", ["blocks"])).to match_array [relations[1], relations[3]]
      expect(filter_relations("type", "!", ["blocks"])).to match_array [relations[0], relations[2]]
    end
  end
end
