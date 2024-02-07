#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
#
require 'spec_helper'
require_module_spec_helper

RSpec.describe Storages::Admin::OAuthAccessGrantNudgeModalComponent, type: :component do # rubocop:disable RSpec/SpecFilePathFormat
  include Rails.application.routes.url_helpers

  shared_let(:project_storage) { create(:project_storage) }

  before do
    render_inline(oauth_access_grant_nudge_modal_component)
  end

  context 'with access pending authorization' do
    let(:oauth_access_grant_nudge_modal_component) { described_class.new(project_storage_id: project_storage.id) }

    it 'renders the nudge modal' do
      expect(page).to have_text('Storage added')
      expect(page).to have_text('You have successfully added a storage to this project. ' \
                                'Would you like to login in the storage and authenticate ' \
                                'your user to start using the storage?')

      expect(page).to have_button('I will do it later')
      expect(page).to have_link('Yes',
                                href: oauth_access_grant_project_settings_project_storage_path(
                                  project_id: project_storage.project_id, id: project_storage
                                ))
    end
  end

  context 'with access authorized' do
    let(:oauth_access_grant_nudge_modal_component) do
      described_class.new(project_storage_id: project_storage.id, authorized: true)
    end

    it 'renders a success modal' do
      expect(page).to have_text('Access granted')
      expect(page).to have_text("You are now ready to use #{project_storage.storage.name}")

      expect(page).to have_button('Close')
    end
  end
end
