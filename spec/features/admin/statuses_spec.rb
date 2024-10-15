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

RSpec.describe "Statuses admin page", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  shared_let(:status_new) { create(:status, name: "New", default_done_ratio: 0, is_default: true) }
  shared_let(:status_in_progress) { create(:status, name: "In Progress", default_done_ratio: 40) }
  shared_let(:status_done) { create(:status, name: "Done", default_done_ratio: 100, is_closed: true, is_readonly: true) }

  before do
    login_as(admin)
  end

  describe "create page" do
    context "with enterprise edition", with_ee: %i[readonly_work_packages] do
      it "has 'is read-only' checkbox unchecked and disabled only when 'is default' is checked (mutually exclusive)" do
        visit new_status_path

        expect(page).not_to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_default))

        # given read-only is checked, when is_default is checked then read-only should become unchecked and disabled
        page.check(Status.human_attribute_name(:is_readonly))
        expect(page).to have_checked_field(Status.human_attribute_name(:is_readonly))
        page.check(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # given read-only is disabled, when is_default is unchecked then read-only should become enabled
        page.uncheck(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: false)
      end
    end

    context "with commmunity edition", with_ee: false do
      it "has 'is read-only' checkbox always disabled" do
        visit new_status_path

        expect(page).to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # check that it remains unchecked
        page.check(Status.human_attribute_name(:is_default))
        page.uncheck(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)
      end
    end
  end

  describe "edit page" do
    it "has 'is default' checkbox disabled for the default status (cannot be unchecked)" do
      visit statuses_path

      click_on "New"
      expect(page).to have_checked_field(Status.human_attribute_name(:is_default), disabled: true)

      page.go_back
      click_on "In Progress"
      expect(page).to have_unchecked_field(Status.human_attribute_name(:is_default), disabled: false)
    end

    context "with enterprise edition", with_ee: %i[readonly_work_packages] do
      it "has 'is read-only' checkbox unchecked and disabled only when 'is default' is checked (mutually exclusive)" do
        visit statuses_path

        click_on "New"
        expect(page).not_to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        page.go_back
        click_on "In Progress"
        expect(page).not_to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_default))

        # given read-only is checked, when is_default is checked then read-only should become unchecked and disabled
        page.check(Status.human_attribute_name(:is_readonly))
        expect(page).to have_checked_field(Status.human_attribute_name(:is_readonly))
        page.check(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # given read-only is disabled, when is_default is unchecked then read-only should become enabled
        page.uncheck(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: false)
      end
    end

    context "with commmunity edition", with_ee: false do
      it "has 'is read-only' checkbox always disabled" do
        visit statuses_path

        click_on "In Progress"
        expect(page).to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # check that it remains unchecked
        page.check(Status.human_attribute_name(:is_default))
        page.uncheck(Status.human_attribute_name(:is_default))
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)

        # readonly statuses are no longer readonly if enterprise edition is not enabled
        page.go_back
        click_on "Done"
        expect(page).to have_enterprise_banner
        expect(page).to have_unchecked_field(Status.human_attribute_name(:is_readonly), disabled: true)
      end
    end
  end
end
