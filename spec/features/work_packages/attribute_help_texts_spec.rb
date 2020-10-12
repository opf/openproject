#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Work package attribute help texts', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:work_package) { FactoryBot.create :work_package, project: project }

  let(:instance) do
    FactoryBot.create :work_package_help_text,
                      attribute_name: :status,
                      help_text: 'Some **help text** for status.'
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

  shared_examples 'allows to view help texts' do
    it 'shows an indicator for whatever help text exists' do
      expect(page).to have_selector('.work-package--single-view .help-text--for-status')

      # Open help text modal
      modal.open!
      expect(modal.modal_container).to have_selector('strong', text: 'help text')
      modal.expect_edit(admin: user.admin?)

      modal.close!
    end
  end

  describe 'as admin' do
    let(:user) { FactoryBot.create(:admin) }
    it_behaves_like 'allows to view help texts'
  end

  describe 'as regular user' do
    let(:view_wps_role) do
      FactoryBot.create :role, permissions: [:view_work_packages]
    end
    let(:user) do
      FactoryBot.create :user,
                        member_in_project: project,
                        member_through_role: view_wps_role
    end

    it_behaves_like 'allows to view help texts'
  end
end
