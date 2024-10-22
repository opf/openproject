#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require "spec_helper"

RSpec.describe API::V3::PlaceholderUsers::PlaceholderUserSqlRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:json) do
    API::V3::Utilities::SqlRepresenterWalker
      .new(scope,
           current_user:,
           url_query: { select: })
      .walk(described_class)
      .to_json
  end

  let(:scope) do
    PlaceholderUser
      .where(id: placeholder_user.id)
  end

  let(:placeholder_user) { create(:placeholder_user) }

  let(:select) { { "*" => {} } }

  current_user do
    create(:user)
  end

  context "when rendering all supported properties" do
    let(:expected) do
      {
        _type: "PlaceholderUser",
        id: placeholder_user.id,
        name: placeholder_user.name,
        email: "",
        _links: {
          self: {
            href: api_v3_paths.placeholder_user(placeholder_user.id),
            title: placeholder_user.name
          }
        }
      }
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql(expected.to_json)
    end
  end
end
