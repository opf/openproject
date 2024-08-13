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

RSpec.describe "Work package attribute help texts", :js do
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  let(:instance) do
    create(:work_package_help_text,
           attribute_name: :status,
           help_text: "Some **help text** for status.")
  end

  let(:modal) { Components::AttributeHelpTextModal.new(instance) }
  let(:wp_page) { Pages::FullWorkPackage.new work_package }

  before do
    work_package
    instance
    login_as(user)

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  shared_examples "allows to view help texts" do
    it "shows an indicator for whatever help text exists" do
      expect(page).to have_css('.work-package--single-view [data-qa-help-text-for="status"]')

      # Open help text modal
      modal.open!
      expect(modal.modal_container).to have_css("strong", text: "help text")
      modal.expect_edit(editable: user.allowed_globally?(:edit_attribute_help_texts))

      modal.close!
    end
  end

  describe "as admin" do
    let(:user) { create(:admin) }

    it_behaves_like "allows to view help texts"
  end

  describe "as regular user" do
    let(:user) do
      create(:user, member_with_permissions: { project => [:view_work_packages] })
    end

    it_behaves_like "allows to view help texts"
  end
end
