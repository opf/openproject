#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

RSpec.describe Storages::Admin::ConfigurationCompletionChecksComponent,
               type: :component do
  describe '#render?' do
    context 'with all configuration checks complete' do
      it 'returns false, does not render view component' do
        storage = build_stubbed(:nextcloud_storage, :as_automatically_managed,
                                oauth_application: build_stubbed(:oauth_application),
                                oauth_client: build_stubbed(:oauth_client))
        component = described_class.new(storage:)

        expect(render_inline(component).content).to be_blank
      end
    end

    context 'with incomplete configuration checks' do
      it 'returns true, renders view component' do
        storage = build_stubbed(:nextcloud_storage, host: nil, name: nil)
        component = described_class.new(storage:)

        expect(render_inline(component)).to have_content('The setup of this storage is incomplete.')
      end
    end
  end
end
