#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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
require 'rack/test'

require_relative './shared_responses'

describe 'BCF 2.1 project extensions resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  shared_let(:type_task) { FactoryBot.create :type_task }
  shared_let(:status) { FactoryBot.create :default_status }
  shared_let(:project) { FactoryBot.create(:project, enabled_module_names: [:bcf], types: [type_task]) }
  subject(:response) { JSON.parse(last_response.body) }

  let(:path) { "/api/bcf/2.1/projects/#{project.id}/extensions" }

  context 'with only view_project permissions' do
    let(:current_user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: [:view_project])
    end

    before do
      login_as(current_user)
      get path
    end

    it 'outputs read-only data', :aggregate_failures do
      expect(response['topic_type']).to include type_task.name
      expect(response['topic_status']).to include status.name

      expect(response['user_id_type']).to be_empty

      expect(response['project_actions']).to be_empty
      expect(response['topic_actions']).to be_empty
      expect(response['comment_actions']).to be_empty
    end
  end

  context 'with edit permissions in project' do
    let(:current_user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: [:view_project, :edit_project, :manage_bcf, :view_members])
    end

    let(:other_user) {
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: [:view_project])
    }

    before do
      other_user
      login_as(current_user)
      get path
    end

    it 'outputs all actions' do
      expect(response['topic_type']).to include type_task.name
      expect(response['topic_status']).to include status.name

      expect(response['user_id_type']).to include(current_user.mail)
      expect(response['user_id_type']).to include(other_user.mail)

      expect(response['project_actions']).to eq %w[update createTopic]

      expect(response['topic_actions']).to eq %w[update updateRelatedTopics updateFiles createComment createViewpoint]
      expect(response['comment_actions']).to eq %w[update]
    end
  end
end
