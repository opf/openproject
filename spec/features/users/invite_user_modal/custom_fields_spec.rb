#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
feature 'Invite user modal custom fields', type: :feature, js: true do
  shared_let(:project) { FactoryBot.create :project }

  let(:permissions) { %i[view_project manage_members] }
  let(:global_permissions) { %i[manage_user] }
  let(:principal) { FactoryBot.build :invited_user }
  let(:modal) do
    ::Components::Users::InviteUserModal.new project: project,
                                             principal: principal,
                                             role: role
  end
  let!(:role) do
    FactoryBot.create :role,
                      name: 'Member',
                      permissions: permissions
  end

  let!(:boolean_cf) { FactoryBot.create :boolean_user_custom_field, name: 'bool', is_required: true }
  let!(:integer_cf) { FactoryBot.create :integer_user_custom_field, name: 'int', is_required: true }
  let!(:text_cf) { FactoryBot.create :text_user_custom_field, name: 'Text', is_required: true }
  let!(:string_cf) { FactoryBot.create :string_user_custom_field, name: 'String', is_required: true }
  # TODO float not supported yet
  #let!(:float_cf) { FactoryBot.create :float_user_custom_field, name: 'Float', is_required: true }
  let!(:list_cf) { FactoryBot.create :list_user_custom_field, name: 'List', is_required: true }
  let!(:list_multi_cf) { FactoryBot.create :list_user_custom_field, name: 'Multi list', multi_value: true, is_required: true }

  let!(:non_req_cf) { FactoryBot.create :string_user_custom_field, name: 'non req', is_required: false }

  let(:boolean_field) { ::FormFields::InputFormField.new boolean_cf }
  let(:integer_field) { ::FormFields::InputFormField.new integer_cf }
  let(:text_field) { ::FormFields::EditorFormField.new text_cf }
  let(:string_field) { ::FormFields::InputFormField.new string_cf }
  # TODO float not supported yet
  #let(:float_field) { ::FormFields::InputFormField.new float_cf }
  let(:list_field) { ::FormFields::SelectFormField.new list_cf }
  let(:list_multi_field) { ::FormFields::SelectFormField.new list_multi_cf }

  let(:quick_add) { ::Components::QuickAddMenu.new }

  current_user do
    FactoryBot.create :user,
                      :skip_validations,
                      member_in_project: project,
                      member_through_role: role,
                      global_permissions: global_permissions
  end

  it 'shows the required fields during the principal step' do
    visit home_path

    quick_add.expect_visible

    quick_add.toggle

    quick_add.click_link 'Invite user'

    modal.project_step

    # Fill the principal and try to go to next
    sleep 1
    modal.principal_step

    expect(page).to have_selector('form.ng-invalid', wait: 10)

    modal.within_modal do
      expect(page).to have_text "bool can't be blank."
      expect(page).to have_text "int can't be blank."
      expect(page).to have_text "Text can't be blank."
      expect(page).to have_text "String can't be blank."
      expect(page).to have_text "List can't be blank."
      expect(page).to have_text "Multi list can't be blank."

      # Does not show the non req field
      expect(page).to have_no_text non_req_cf.name
    end

    # Fill all fields
    boolean_field.input_element.check
    integer_field.set_value '1234'
    text_field.set_value 'A **markdown** value'
    string_field.set_value 'String value'

    list_field.select_option '1'
    list_multi_field.select_option '1', '2'

    modal.click_next

    # Remaining steps
    modal.role_step
    modal.invitation_step
    modal.confirmation_step
    modal.click_modal_button 'Send invitation'
    modal.expect_text "Invite #{principal.mail} to #{project.name}"

    # Close
    modal.click_modal_button 'Send invitation'
    modal.expect_text "#{principal.mail} was invited!"

    # Expect to be added to project
    invited = project.users.last
    expect(invited.mail).to eq principal.mail

    expect(invited.custom_value_for(boolean_cf).typed_value).to eq true
    expect(invited.custom_value_for(integer_cf).typed_value).to eq 1234
    expect(invited.custom_value_for(text_cf).typed_value).to eq 'A **markdown** value'
    expect(invited.custom_value_for(string_cf).typed_value).to eq 'String value'
    expect(invited.custom_value_for(list_cf).typed_value).to eq '1'
    expect(invited.custom_value_for(list_multi_cf).map(&:typed_value)).to eq %w[1 2]
  end
end
