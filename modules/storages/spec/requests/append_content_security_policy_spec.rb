#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'
require_module_spec_helper

describe 'Appendix of default CSP for external file storage hosts' do
  shared_let(:project) { create(:project) }
  shared_let(:storage) { create(:storage) }
  shared_let(:project_storage) { create(:project_storage, project:, storage:) }

  describe 'GET /' do
    context 'when logged in' do
      current_user { create(:user, member_in_project: project, member_with_permissions: %i[manage_file_links]) }

      it 'appends to storage host to the connect-src CSP' do
        get '/'

        expect(last_response.headers['Content-Security-Policy']).to match /#{storage.host}/
      end
    end

    context 'when not logged in' do
      it 'does not append the storage host to connect-src CSP' do
        get '/'

        expect(last_response.headers['Content-Security-Policy']).not_to match /#{storage.host}/
      end
    end
  end
end
