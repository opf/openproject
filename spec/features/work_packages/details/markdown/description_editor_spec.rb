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
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/edit_fields/edit_field'
require 'features/work_packages/work_packages_page'

describe 'description inplace editor', js: true, selenium: true do
  let(:project) { FactoryBot.create :project_with_types, public: true }
  let(:property_name) { :description }
  let(:property_title) { 'Description' }
  let(:description_text) { 'Ima description' }
  let!(:work_package) do
    FactoryBot.create(
      :work_package,
      project: project,
      description: description_text
    )
  end
  let(:user) { FactoryBot.create :admin }
  let(:field) { TextEditorField.new wp_page, 'description' }
  let(:wp_page) { Pages::SplitWorkPackage.new(work_package, project) }

  before do
    login_as(user)

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  context 'with permission' do
    it 'allows editing description field' do
      field.expect_state_text(description_text)

      # Regression test #24033
      # Cancelling an edition several tiems properly resets the value
      field.activate!

      field.set_value "My intermittent edit 1"
      field.cancel_by_escape

      field.activate!
      field.set_value "My intermittent edit 2"
      field.cancel_by_click

      field.activate!
      field.expect_value description_text
      field.cancel_by_click

      # Activate the field
      field.activate!

      # Pressing escape does nothing here
      field.cancel_by_escape
      field.expect_active!

      # Cancelling through the action panel
      field.cancel_by_click
      field.expect_inactive!
    end
  end

  context 'when is empty' do
    let(:description_text) { '' }

    it 'renders a placeholder' do
      field.expect_state_text 'Description: Click to edit...'

      field.activate!
      # An empty description is also allowed
      field.expect_save_button(enabled: true)
      field.set_value 'A new hope ...'
      field.expect_save_button(enabled: true)
      field.submit_by_click

      wp_page.expect_notification message: I18n.t('js.notice_successful_update')
      field.expect_state_text 'A new hope ...'
    end
  end

  context 'with no permission' do
    let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
    let(:role) { FactoryBot.create :role, permissions: %i(view_work_packages) }

    it 'does not show the field' do
      expect(page).to have_no_selector('.inline-edit--display-field.description.-editable')

      field.display_element.click
      field.expect_inactive!
    end

    context 'when is empty' do
      let(:description_text) { '' }

      it 'renders a placeholder' do
        field.expect_state_text ''
      end
    end
  end

  it_behaves_like 'a workpackage autocomplete field'
  it_behaves_like 'a principal autocomplete field'
end
