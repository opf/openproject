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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Document categories", :js do
  include Rails.application.routes.url_helpers

  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  it "renders a deprecation notice" do
    visit admin_settings_document_categories_path

    expect(page).to have_heading("File categories are now called 'Document types'")
    expect(page).to have_content("Your existing file categories have been converted to document types " \
                                 "with the introduction of the new Documents module. " \
                                 "All existing documents have also been migrated to these new types.")

    expect(page).to have_link("Configure document types", href: admin_settings_document_types_path)
    expect(page).to have_link("Learn more about the Documents module",
                              href: "https://www.openproject.org/docs/user-guide/documents/?go_to_locale=en")
  end

  context "as non-admin" do
    shared_let(:non_admin) { create(:user) }

    before do
      login_as(non_admin)
    end

    it "denies access" do
      visit admin_settings_document_categories_path

      expect(page).to have_content("You are not authorized to access this page.")
    end
  end
end
