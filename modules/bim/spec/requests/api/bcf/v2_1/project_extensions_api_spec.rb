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
require 'rack/test'

require_relative './shared_responses'

describe 'BCF 2.1 project extensions resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  shared_let(:type_task) { FactoryBot.create :type_task }
  shared_let(:status) { FactoryBot.create :default_status }
  shared_let(:priority) { FactoryBot.create :default_priority }
  shared_let(:project) { FactoryBot.create(:project, enabled_module_names: [:bim], types: [type_task]) }
  subject(:response) { last_response }

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

    it_behaves_like 'bcf api successful response' do
      let(:expected_body) do
        {
          topic_type: [],
          topic_status: [],
          priority: [],
          snippet_type: [],
          stage: [],
          topic_label: [],
          user_id_type: [],
          project_actions: [],
          topic_actions: [],
          comment_actions: []
        }
      end
    end
  end

  context 'with edit permissions in project' do
    let(:current_user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: [:view_project, :edit_project, :manage_bcf, :view_members])
    end

    let(:other_user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: [:view_project])
    end

    before do
      other_user
      login_as(current_user)
      get path
    end

    it_behaves_like 'bcf api successful response expectation' do
      let(:expectations) do
        ->(body) {
          hash = JSON.parse(body)

          expect(hash.keys).to match_array %w[
            topic_type topic_status user_id_type project_actions topic_actions comment_actions
            stage snippet_type priority topic_label
          ]

          expect(hash['topic_type']).to include type_task.name
          expect(hash['topic_status']).to include status.name

          expect(hash['user_id_type']).to include(other_user.mail, current_user.mail)

          expect(hash['project_actions']).to eq %w[update viewTopic createTopic]

          expect(hash['topic_actions']).to eq %w[update updateRelatedTopics updateFiles createViewpoint]
          expect(hash['comment_actions']).to eq []
        }
      end
    end
  end
end
