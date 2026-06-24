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

RSpec.describe Users::FormComponent, type: :component do
  let(:current_user) { build_stubbed(:admin) }
  let(:contract) { instance_double(Users::UpdateContract, writable?: true) }

  before do
    User.current = current_user
  end

  def render_component(user:)
    render_in_view_context(user, contract) do |form_user, form_contract|
      primer_form_with(model: form_user, url: "/users") do |form|
        render(Users::FormComponent.new(builder: form, user: form_user, contract: form_contract))
      end
    end
  end

  context "for a new user" do
    it "renders the attributes and a single create button, but no password block" do
      render_component(user: User.new)

      expect(page).to have_field("user[firstname]")
      expect(page).to have_button(I18n.t(:button_create))
      expect(page).to have_no_button(I18n.t(:button_create_and_continue))
      expect(page).to have_no_css("[data-admin--users-target='passwordFields']", visible: :all)
    end
  end

  context "for a persisted internal user edited by an admin" do
    let(:user) { create(:user) }

    it "renders status, the password block, preferences and a Save button" do
      render_component(user:)

      expect(page).to have_css("[data-admin--users-target='passwordFields']", visible: :all)
      expect(page).to have_select("pref[time_zone]")
      expect(page).to have_button(I18n.t(:button_save))
    end

    it "renders the consent status when consent is required" do
      allow(Setting).to receive(:consent_required?).and_return(true)

      render_component(user:)

      expect(page).to have_text(I18n.t("consent.title"))
    end
  end

  context "for a persisted external-auth user" do
    let(:user) { create(:user, identity_url: "saml:user-id") }

    before { allow(user).to receive(:uses_external_authentication?).and_return(true) }

    it "renders the read-only authentication provider instead of the password block" do
      render_component(user:)

      expect(page).to have_text(I18n.t("user.authentication_provider"))
      expect(page).to have_no_css("[data-admin--users-target='passwordFields']", visible: :all)
    end
  end
end
