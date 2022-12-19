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

require_relative '../spec_helper'

# These specs mainly check that error messages from a sub-service
# (about unsafe hosts with HTTP protocol) are passed to the main form.
describe OpenProject::Storages::AppendContentSecurityPolicy do
  let(:permissions) { %i(manage_file_links) }
  let(:project) { create(:project) }
  let(:current_user) { create(:user, member_in_project: project, member_with_permissions: permissions) }
  let(:storage) { create(:storage) }
  let(:project_storage) { create(:project_storage, project:, storage:) }

  before do
    current_user
    storage
    project_storage

    login_as current_user
  end

  shared_examples 'appends hosts to CSP' do
    let(:controller) { instance_double(ApplicationController) }
    let(:context) { { controller: } }

    before do
      allow(controller).to receive(:append_content_security_policy_directives)

      instance = described_class.instance
      instance.application_controller_before_action(context)
    end

    it 'secure_header helper function for appending CSP is called with correct storage hosts' do
      expect(controller).to have_received(:append_content_security_policy_directives)
                              .with({ connect_src: expected_hosts })
    end
  end

  context 'on happy path' do
    let(:expected_hosts) { [storage.host] }

    it_behaves_like 'appends hosts to CSP'
  end

  context 'when current user is admin without being a member of any project' do
    let(:current_user) { create(:admin) }
    let(:expected_hosts) { [storage.host] }

    it_behaves_like 'appends hosts to CSP'
  end

  context 'without correct permission' do
    let(:permissions) { [] }
    let(:expected_hosts) { [] }

    it_behaves_like 'appends hosts to CSP'
  end

  context 'without the storage being active in a project' do
    let(:project_storage) { nil }
    let(:expected_hosts) { [] }

    it_behaves_like 'appends hosts to CSP'
  end

  context 'without the storage' do
    let(:project_storage) { nil }
    let(:storage) { nil }
    let(:expected_hosts) { [] }

    it_behaves_like 'appends hosts to CSP'
  end
end
