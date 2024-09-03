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

RSpec.describe API::V3::Actions::ActionSqlRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:scope) do
    Action
      .where(id: action_id)
      .limit(1)
  end
  let(:action_id) do
    "memberships/create"
  end

  current_user do
    create(:user)
  end

  subject(:json) do
    API::V3::Utilities::SqlRepresenterWalker
      .new(scope,
           current_user:,
           url_query: { select: { "id" => {}, "_type" => {}, "self" => {} } })
      .walk(API::V3::Actions::ActionSqlRepresenter)
      .to_json
  end

  context "with a project action" do
    it "renders as expected" do
      expect(json)
        .to be_json_eql({
          id: action_id,
          _type: "Action",
          _links: {
            self: {
              href: api_v3_paths.action(action_id)
            }
          }
        }.to_json)
    end
  end
end
