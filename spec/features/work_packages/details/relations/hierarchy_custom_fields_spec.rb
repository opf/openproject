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

describe 'creating a child directly after the wp itself was created', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project, types: [type]) }
  let(:wp_page) { Pages::FullWorkPackageCreate.new }

  let!(:status) { FactoryBot.create(:status, is_default: true) }
  let!(:priority) { FactoryBot.create(:priority, is_default: true) }
  let(:type) { FactoryBot.create(:type, custom_fields: [custom_field]) }
  let(:custom_field) { FactoryBot.create :work_package_custom_field,
                                         field_format: 'int',
                                         is_for_all: true
  }
  let(:relations_tab) { find('.tabrow li', text: 'RELATIONS') }

  before do
    login_as user
    visit new_project_work_packages_path(project.identifier, type: type.id)
    expect_angular_frontend_initialized
    loading_indicator_saveguard
  end

  it 'keeps its custom field values (regression #29511, #29446)' do
    # Set subject
    subject = wp_page.edit_field :subject
    subject.set_value 'My subject'

    # Set CF
    cf = wp_page.edit_field "customField#{custom_field.id}"
    cf.set_value '42'

    # Save WP
    wp_page.save!
    wp_page.expect_and_dismiss_notification(message: 'Successful creation.')

    # Add child
    scroll_to_and_click relations_tab
    find('.wp-inline-create--add-link.wp-inline-create--split-link').click
    fill_in 'wp-new-inline-edit--field-subject', with: 'A child WP'
    find('#wp-new-inline-edit--field-subject').native.send_keys(:return)

    # Expect CF value to be still visible
    wp_page.expect_and_dismiss_notification(message: 'Successful creation.')
    expect(wp_page).to have_selector('wp-relations-count', text: 1)
    wp_page.expect_attributes "customField#{custom_field.id}": '42'
  end
end
