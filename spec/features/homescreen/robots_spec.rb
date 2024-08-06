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

RSpec.describe "robots.txt" do
  let!(:project) { create(:public_project) }

  before do
    visit "/robots.txt"
  end

  context "when login_required", with_settings: { login_required: true } do
    it "disallows everything" do
      expect(page).to have_content("Disallow: /")
    end
  end

  context "when not login_required", with_settings: { login_required: false } do
    it "disallows global paths and paths from public project" do
      expect(page).to have_content("Disallow: /activity")
      expect(page).to have_content("Disallow: /activities")
      expect(page).to have_content("Disallow: /search")

      [project.identifier, project.id].each do |identifier|
        expect(page).to have_content("Disallow: /projects/#{identifier}/repository")
        expect(page).to have_content("Disallow: /projects/#{identifier}/work_packages")
        expect(page).to have_content("Disallow: /projects/#{identifier}/activity")
        expect(page).to have_content("Disallow: /projects/#{identifier}/search")
      end
    end
  end
end
