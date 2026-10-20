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

require "rails_helper"

RSpec.describe AdminElevationSessions::ElevateDialogComponent, type: :component do
  let(:project) { build_stubbed(:project, name: "Apollo") }
  let(:back_url) { "/projects/apollo/work_packages" }
  let(:password_checkable) { true }
  let(:user) { build_stubbed(:admin) }
  let(:component_args) { {} }

  before { allow(user).to receive(:password_checkable?).and_return(password_checkable) }

  subject(:rendered) { render_inline(described_class.new(project:, user:, back_url:, **component_args)) }

  it "names the project in the title" do
    rendered

    expect(page).to have_text(I18n.t("admin_elevation.dialog.title", project: "Apollo"))
  end

  it "explains the idle timeout", with_settings: { admin_elevation_idle_timeout: 45 } do
    rendered

    expect(page).to have_text(I18n.t("admin_elevation.dialog.description", minutes: 45))
  end

  it "asks for the password" do
    rendered

    expect(page).to have_field(User.human_attribute_name(:password), type: :password)
  end

  context "with a wrong password entered before" do
    let(:component_args) { { password_error: "The entered password is not correct." } }

    it "shows the error on the password field" do
      rendered

      expect(page).to have_text("The entered password is not correct.")
    end
  end

  context "for a user without a password" do
    let(:password_checkable) { false }

    it "does not ask for a password" do
      rendered

      expect(page).to have_no_field(User.human_attribute_name(:password))
    end
  end

  it "asks whether to include the subprojects" do
    rendered

    expect(page).to have_field(I18n.t("admin_elevation.dialog.include_subprojects"),
                               type: :checkbox, checked: false)
  end

  context "with the subprojects included before" do
    let(:component_args) { { include_subprojects: true } }

    it "keeps the subprojects checked" do
      rendered

      expect(page).to have_field(I18n.t("admin_elevation.dialog.include_subprojects"),
                                 type: :checkbox, checked: true)
    end
  end

  it "posts the form to the elevation of the project", :aggregate_failures do
    rendered

    expect(page).to have_element(:form, action: "/projects/#{project.identifier}/admin_elevation", method: "post")
    expect(page).to have_field("back_url", type: :hidden, with: back_url)
    expect(page).to have_button(I18n.t("admin_elevation.dialog.submit"))
  end

  context "without a back url" do
    let(:back_url) { nil }

    it "does not render the back url" do
      rendered

      expect(page).to have_no_field("back_url", type: :hidden)
    end
  end
end
