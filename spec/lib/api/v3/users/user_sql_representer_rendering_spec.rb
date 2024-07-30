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

RSpec.describe API::V3::Users::UserSqlRepresenter, "rendering" do
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
    User
      .where(id: rendered_user.id)
  end

  let(:rendered_user) { current_user }

  let(:select) { { "*" => {} } }

  current_user do
    create(:user)
  end

  context "when rendering all supported properties" do
    let(:expected) do
      {
        _type: "User",
        id: current_user.id,
        name: current_user.name,
        firstname: current_user.firstname,
        lastname: current_user.lastname,
        _links: {
          self: {
            href: api_v3_paths.user(current_user.id),
            title: current_user.name
          }
        }
      }
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql(expected.to_json)
    end
  end

  describe "name property" do
    shared_examples_for "name property depending on user format setting" do
      let(:select) { { "name" => {} } }

      let(:expected) do
        {
          name: current_user.name
        }
      end

      it "renders as expected" do
        expect(json)
          .to be_json_eql(expected.to_json)
      end
    end

    context "when user_format is set to firstname", with_settings: { user_format: :firstname } do
      it_behaves_like "name property depending on user format setting"
    end

    context "when user_format is set to lastname_firstname", with_settings: { user_format: :lastname_firstname } do
      it_behaves_like "name property depending on user format setting"
    end

    context "when user_format is set to lastname_coma_firstname", with_settings: { user_format: :lastname_coma_firstname } do
      it_behaves_like "name property depending on user format setting"
    end

    context "when user_format is set to lastname_n_firstname", with_settings: { user_format: :lastname_n_firstname } do
      it_behaves_like "name property depending on user format setting"
    end

    context "when user_format is set to username", with_settings: { user_format: :username } do
      it_behaves_like "name property depending on user format setting"
    end
  end

  describe "firstname property" do
    let(:select) { { "firstname" => {} } }

    context "when the user is the current user" do
      it "renders the firstname" do
        expect(json)
          .to be_json_eql(
            {
              firstname: rendered_user.firstname
            }.to_json
          )
      end
    end

    context "when the user is a user not having manage_user permission" do
      let(:rendered_user) { create(:user) }

      it "hides the firstname" do
        expect(json)
          .to be_json_eql({}.to_json)
      end
    end

    context "when the user is a user having manage_user permission" do
      let(:current_user) { create(:user, global_permissions: [:manage_user]) }
      let(:rendered_user) { create(:user) }

      it "renders the firstname" do
        expect(json)
          .to be_json_eql(
            {
              firstname: rendered_user.firstname
            }.to_json
          )
      end
    end
  end

  describe "lastname property" do
    let(:select) { { "lastname" => {} } }

    context "when the user is the current user" do
      it "renders the lastname" do
        expect(json)
          .to be_json_eql(
            {
              lastname: rendered_user.lastname
            }.to_json
          )
      end
    end

    context "when the user is a user not having manage_user permission" do
      let(:rendered_user) { create(:user) }

      it "hides the lastname" do
        expect(json)
          .to be_json_eql({}.to_json)
      end
    end

    context "when the user is a user having manage_user permission" do
      let(:current_user) { create(:user, global_permissions: [:manage_user]) }
      let(:rendered_user) { create(:user) }

      it "renders the lastname" do
        expect(json)
          .to be_json_eql(
            {
              lastname: rendered_user.lastname
            }.to_json
          )
      end
    end
  end
end
