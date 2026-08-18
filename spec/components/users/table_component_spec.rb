# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) The OpenProject GmbH
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

require "rails_helper"

RSpec.describe Users::TableComponent, type: :component do
  let(:current_user) { create(:admin) }
  let!(:alice) { create(:user, login: "alice", firstname: "Alice", lastname: "Adams", mail: "alice@example.com") }
  let!(:bob) { create(:user, login: "bob", firstname: "Bob", lastname: "Brown", mail: "bob@example.com") }

  let(:query) { UserQuery.new(user: current_user) }

  before { login_as(current_user) }

  subject(:rendered_component) do
    with_request_url("/users") do
      allow(vc_test_controller).to receive_messages(controller_name: "users", action_name: "index")

      render_inline(described_class.new(rows: query, current_user:))
    end
  end

  it "renders one row per user" do
    expect(rendered_component).to have_text("alice")
    expect(rendered_component).to have_text("bob")
  end

  it "renders the mail column" do
    expect(rendered_component).to have_link("alice@example.com")
  end

  it "renders a header for each default column" do
    expect(rendered_component).to have_text(User.human_attribute_name(:login))
    expect(rendered_component).to have_text(User.human_attribute_name(:mail))
  end

  it "renders a sort link for a sortable column" do
    expect(rendered_component).to have_css("a[href*='sort=login']")
  end

  it "renders a descending-first sort link for created_at" do
    expect(rendered_component).to have_css("a[href*='created_at%3Adesc']")
  end

  it "renders the status action link for each user" do
    expect(rendered_component).to have_css("a[href*='change_status']", minimum: 1)
  end

  context "with an explicit column selection" do
    let(:query) do
      q = UserQuery.new(user: current_user)
      q.select(:login, :admin)
      q
    end

    it "renders only the selected columns" do
      expect(rendered_component).to have_text("alice")
      expect(rendered_component).to have_no_link("alice@example.com")
    end
  end

  context "with a custom field column selected" do
    let!(:custom_field) { create(:user_custom_field, :string, name: "Nickname") }

    let(:query) do
      q = UserQuery.new(user: current_user)
      q.select(:login, :"cf_#{custom_field.id}")
      q
    end

    before do
      alice.custom_field_values = { custom_field.id => "Ali" }
      alice.save!
    end

    it "renders the custom field's heading and value" do
      expect(rendered_component).to have_text("Nickname")
      expect(rendered_component).to have_text("Ali")
    end
  end

  context "with no matching users" do
    let(:query) do
      q = UserQuery.new(user: current_user)
      q.where("login", "=", ["nobody"])
      q
    end

    it "renders no user rows and no pagination" do
      expect(rendered_component).to have_no_text("alice")
      expect(rendered_component).to have_no_css(".op-pagination")
    end
  end
end
