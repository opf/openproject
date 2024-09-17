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

RSpec.describe "Localization", with_settings: { login_required?: false,
                                                available_languages: %w[de en],
                                                default_language: "en" } do
  context "with a HTTP header Accept-Language having a valid supported language" do
    before do
      Capybara.current_session.driver.header("Accept-Language", "de,de-de;q=0.8,en-us;q=0.5,en;q=0.3")
    end

    it "uses the language from HTTP header Accept-Language" do
      visit projects_path

      expect(page)
        .to have_content("Projekte")
    end
  end

  context "with a HTTP header Accept-Language having an unsupported language" do
    before do
      Capybara.current_session.driver.header("Accept-Language", "zz")
    end

    it "uses the default language configured in administration" do
      visit projects_path

      expect(page).to have_content("Projects")
    end
  end
end
