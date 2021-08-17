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
require 'rack/test'

describe 'API v3 Work package resource',
         type: :request,
         content_type: :json do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  let(:closed_status) { FactoryBot.create(:closed_status) }

  let(:work_package) do
    FactoryBot.create(:work_package,
                      project_id: project.id,
                      description: 'lorem ipsum')
  end
  let(:project) do
    FactoryBot.create(:project, identifier: 'test_project', public: false)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }
  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:unauthorize_user) { FactoryBot.create(:user) }
  let(:type) { FactoryBot.create(:type) }

  before do
    login_as(current_user)
  end

  describe 'GET /api/v3/work_packages/:id' do
    let(:get_path) { api_v3_paths.work_package work_package.id }

    context 'when acting as a user with permission to view work package' do
      before(:each) do
        login_as(current_user)
        get get_path
      end

      it 'should respond with 200' do
        expect(last_response.status).to eq(200)
      end

      describe 'response body' do
        subject { last_response.body }
        let!(:other_wp) do
          FactoryBot.create(:work_package,
                            project_id: project.id,
                            status: closed_status)
        end
        let(:work_package) do
          FactoryBot.create(:work_package,
                            project_id: project.id,
                            description: description).tap do |wp|
            wp.children << children
          end
        end
        let(:children) { [] }
        let(:description) do
          <<~DESCRIPTION
            <macro class="toc"><macro>

            # OpenProject Masterplan for 2015

            ## three point plan

            1) One ###{other_wp.id}
            2) Two
            3) Three

            ### random thoughts

            ### things we like

            * Pointed
            * Relaxed
            * Debonaire
          DESCRIPTION
        end

        it 'responds with work package in HAL+JSON format' do
          expect(subject)
            .to be_json_eql(work_package.id.to_json)
                  .at_path('id')
        end

        describe "description" do
          subject { JSON.parse(last_response.body)['description'] }

          it 'renders to html' do
            is_expected.to have_selector('h1')
            is_expected.to have_selector('h2')

            # resolves links
            expect(subject['html'])
              .to have_selector("macro.macro--wp-quickinfo[data-id='#{other_wp.id}']")
            # resolves macros, e.g. toc
            expect(subject['html'])
              .to have_selector('.op-uc-toc--list-item', text: "OpenProject Masterplan for 2015")
          end
        end

        describe 'derived dates' do
          let(:children) do
            # This will be in another project but the user is still allowed to see the dates
            [FactoryBot.create(:work_package,
                               start_date: Date.today,
                               due_date: Date.today + 5.days)]
          end

          it 'has derived dates' do
            is_expected
              .to be_json_eql(Date.today.to_json)
                    .at_path('derivedStartDate')

            is_expected
              .to be_json_eql((Date.today + 5.days).to_json)
                    .at_path('derivedDueDate')
          end
        end

        describe 'relations' do
          let(:directly_related_wp) do
            FactoryBot.create(:work_package, project_id: project.id)
          end
          let(:transitively_related_wp) do
            FactoryBot.create(:work_package, project_id: project.id)
          end

          let(:work_package) do
            FactoryBot.create(:work_package,
                              project_id: project.id,
                              description: 'lorem ipsum').tap do |wp|
              FactoryBot.create(:relation, relates: 1, from: wp, to: directly_related_wp)
              FactoryBot.create(:relation, relates: 1, from: directly_related_wp, to: transitively_related_wp)
            end
          end

          it 'embeds all direct relations' do
            expect(subject)
              .to be_json_eql(1.to_json)
                    .at_path('_embedded/relations/total')

            expect(subject)
              .to be_json_eql(api_v3_paths.work_package(directly_related_wp.id).to_json)
                    .at_path('_embedded/relations/_embedded/elements/0/_links/to/href')
          end
        end
      end

      context 'requesting nonexistent work package' do
        let(:get_path) { api_v3_paths.work_package 909090 }

        it_behaves_like 'not found'
      end
    end

    context 'when acting as a user without permission to view work package' do
      before(:each) do
        allow(User).to receive(:current).and_return unauthorize_user
        get get_path
      end

      it_behaves_like 'not found'
    end

    context 'when acting as an anonymous user' do
      before(:each) do
        allow(User).to receive(:current).and_return User.anonymous
        get get_path
      end

      it_behaves_like 'not found'
    end
  end
end
