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

RSpec.describe "Statuses administration" do
  current_user { create(:admin) }

  describe "New status page" do
    before do
      visit new_status_path
    end

    describe "with EE token", with_ee: %i[readonly_work_packages] do
      it "allows to set readonly status" do
        expect(page).to have_field "status[is_readonly]", disabled: false
      end
    end

    describe "without EE token" do
      it "does not allow to set readonly status" do
        expect(page).to have_field "status[is_readonly]", disabled: true
      end
    end
  end

  describe "Work Package statuses page" do
    context "without any statuses" do
      it 'displays the "no results" text' do
        visit statuses_path
        expect(page).to have_content(I18n.t("no_results_title_text"))
      end
    end

    context "with some statuses" do
      let!(:new_status) { create(:default_status, name: "I am new") }
      let!(:in_progress_status) { create(:status, name: "Working on it") }
      let!(:closed_status) { create(:closed_status, name: "Job finished") }

      it "list statuses" do
        visit statuses_path
        expect(page).to have_content("I am new")
        expect(page).to have_content("Working on it")
        expect(page).to have_content("Job finished")
      end
    end
  end
end
