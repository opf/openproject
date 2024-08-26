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

class TestRepresenter < API::Decorators::Single
  include ::API::Decorators::LinkedResource
end

RSpec.describe API::V3::Principals::PrincipalRepresenterFactory do
  let(:current_user) { build_stubbed(:user) }

  let(:represented) do
    OpenStruct.new(association_id: 5, association: principal)
  end
  let(:principal) { nil }
  let(:user) { build_stubbed(:user) }
  let(:group) { build_stubbed(:group) }
  let(:placeholder) { build_stubbed(:placeholder_user) }
  let(:deleted) { build_stubbed(:deleted_user) }

  describe ".create" do
    subject { described_class.create principal, current_user: }

    context "with a user" do
      let(:principal) { user }

      it "returns a user representer" do
        expect(subject).to be_a API::V3::Users::UserRepresenter
      end
    end

    context "with a group" do
      let(:principal) { group }

      it "returns a group representer" do
        expect(subject).to be_a API::V3::Groups::GroupRepresenter
      end
    end

    context "with a placeholder user" do
      let(:principal) { placeholder }

      it "returns a user representer" do
        expect(subject).to be_a API::V3::PlaceholderUsers::PlaceholderUserRepresenter
      end
    end

    context "with a deleted user" do
      let(:principal) { deleted }

      it "returns a user representer" do
        expect(subject).to be_a API::V3::Users::UserRepresenter
      end
    end
  end

  describe ".create_link_lambda" do
    subject(:link) do
      TestRepresenter
        .new(represented, current_user:)
        .instance_exec(&described_class.create_link_lambda("association"))
    end

    context "with a user" do
      let(:principal) { user }

      it "renders a link to the user" do
        expect(link)
          .to eql({ "href" => "/api/v3/users/5", "title" => principal.name })
      end
    end

    context "with a group" do
      let(:principal) { group }

      it "renders a link to the group" do
        expect(link)
          .to eql({ "href" => "/api/v3/groups/5", "title" => principal.name })
      end
    end

    context "with a placeholder user" do
      let(:principal) { placeholder }

      it "renders a link to the placeholder" do
        expect(link)
          .to eql({ "href" => "/api/v3/placeholder_users/5", "title" => principal.name })
      end
    end

    context "with a deleted user" do
      let(:principal) { deleted }

      it "renders a link to the user (which is deleted)" do
        expect(link)
          .to eql({ "href" => "/api/v3/users/5", "title" => principal.name })
      end
    end
  end

  describe ".create_getter_lambda" do
    subject(:getter) do
      TestRepresenter
        .new(represented, current_user:, embed_links:)
        .instance_exec(&described_class.create_getter_lambda("association"))
    end

    let(:embed_links) { true }

    context "with a user" do
      let(:principal) { user }

      it "returns a user representer" do
        expect(getter)
          .to be_a API::V3::Users::UserRepresenter
      end
    end

    context "with a group" do
      let(:principal) { group }

      it "renders a group representer" do
        expect(getter)
          .to be_a API::V3::Groups::GroupRepresenter
      end
    end

    context "with a placeholder user" do
      let(:principal) { placeholder }

      it "renders a placeholder representer" do
        expect(getter)
          .to be_a API::V3::PlaceholderUsers::PlaceholderUserRepresenter
      end
    end

    context "with a deleted user" do
      let(:principal) { deleted }

      it "renders a user representer" do
        expect(getter)
          .to be_a API::V3::Users::UserRepresenter
      end
    end

    context "with nil" do
      let(:principal) { nil }

      it "return nil" do
        expect(getter)
          .to be_nil
      end
    end

    context "without embedding links" do
      let(:principal) { user }
      let(:embed_links) { false }

      it "returns a user representer" do
        expect(getter)
          .to be_nil
      end
    end
  end

  describe ".create_setter_lambda" do
    subject(:setter) do
      TestRepresenter
        .new(represented, current_user: nil)
        .instance_exec(fragment: { "href" => link }, &described_class.create_setter_lambda("association"))

      represented.association_id
    end

    context "with a user link" do
      let(:link) { "/api/v3/users/90" }

      it "sets the association" do
        expect(setter)
          .to eql("90")
      end
    end

    context "with a group link" do
      let(:link) { "/api/v3/groups/90" }

      it "sets the association" do
        expect(setter)
          .to eql("90")
      end
    end

    context "with a placeholder user link" do
      let(:link) { "/api/v3/placeholder_users/90" }

      it "sets the association" do
        expect(setter)
          .to eql("90")
      end
    end

    context "with an invalid link" do
      let(:link) { "/api/v3/schum/90" }

      it "raises an exception" do
        expect { setter }
          .to raise_error(API::Errors::InvalidResourceLink)
      end
    end
  end
end
