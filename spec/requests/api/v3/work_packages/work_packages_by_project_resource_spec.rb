#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'spec_helper'
require 'rack/test'

describe API::V3::WorkPackages::WorkPackagesByProjectAPI, type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.build(:user, member_in_project: project, member_through_role: role)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }
  let(:project) { FactoryBot.create(:project_with_types, public: false) }
  let(:path) { api_v3_paths.work_packages_by_project project.id }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#get' do
    let(:work_packages) { [] }
    subject { last_response }

    before do
      work_packages.each(&:save!)
      get path
    end

    it 'succeeds' do
      expect(subject.status).to eql 200
    end

    context 'not allowed to see the project' do
      let(:current_user) { FactoryBot.build(:user) }

      it 'fails with HTTP Not Found' do
        expect(subject.status).to eql 404
      end
    end

    context 'not allowed to see work packages' do
      let(:permissions) { [:view_project] }

      it 'fails with HTTP Not Found' do
        expect(subject.status).to eql 403
      end
    end

    describe 'advanced query options' do
      let(:base_path) { api_v3_paths.work_packages_by_project project.id }
      let(:query) { {} }
      let(:path) { "#{base_path}?#{query.to_query}" }

      describe 'sorting' do
        let(:query) { { sortBy: '[["id", "desc"]]' } }
        let(:work_packages) { FactoryBot.create_list(:work_package, 2, project: project) }

        it 'returns both elements' do
          expect(subject.body).to be_json_eql(2).at_path('count')
          expect(subject.body).to be_json_eql(2).at_path('total')
        end

        it 'returns work packages in the expected order' do
          first_wp = work_packages.first
          last_wp = work_packages.last

          expect(subject.body).to be_json_eql(last_wp.id).at_path('_embedded/elements/0/id')
          expect(subject.body).to be_json_eql(first_wp.id).at_path('_embedded/elements/1/id')
        end
      end

      describe 'filtering' do
        let(:query) do
          {
            filters: [
              {
                priority: {
                  operator: '=',
                  values: [priority1.id.to_s]
                }
              }
            ].to_json
          }
        end
        let(:priority1) { FactoryBot.create(:priority, name: 'Prio A') }
        let(:priority2) { FactoryBot.create(:priority, name: 'Prio B') }
        let(:work_packages) do
          [
            FactoryBot.create(:work_package, project: project, priority: priority1),
            FactoryBot.create(:work_package, project: project, priority: priority2)
          ]
        end

        it 'returns only one element' do
          expect(subject.body).to be_json_eql(1).at_path('count')
          expect(subject.body).to be_json_eql(1).at_path('total')
        end

        it 'returns the matching element' do
          expected_id = work_packages.first.id
          expect(subject.body).to be_json_eql(expected_id).at_path('_embedded/elements/0/id')
        end
      end

      describe 'grouping' do
        let(:query) { { groupBy: 'priority' } }
        let(:priority1) { FactoryBot.build(:priority, name: 'Prio A', position: 2) }
        let(:priority2) { FactoryBot.build(:priority, name: 'Prio B', position: 1) }
        let(:work_packages) do
          [
            FactoryBot.create(:work_package,
                              project: project,
                              priority: priority1,
                              estimated_hours: 1),
            FactoryBot.create(:work_package,
                              project: project,
                              priority: priority2,
                              estimated_hours: 2),
            FactoryBot.create(:work_package,
                              project: project,
                              priority: priority1,
                              estimated_hours: 3)
          ]
        end
        let(:expected_group1) do
          {
            _links: {
              valueLink: [{
                href: api_v3_paths.priority(priority1.id)
              }],
              groupBy: {
                href: api_v3_paths.query_group_by('priority'),
                title: 'Priority'
              }
            },
            value: priority1.name,
            count: 2
          }
        end
        let(:expected_group2) do
          {
            _links: {
              valueLink: [{
                href: api_v3_paths.priority(priority2.id)
              }],
              groupBy: {
                href: api_v3_paths.query_group_by('priority'),
                title: 'Priority'
              }
            },
            value: priority2.name,
            count: 1
          }
        end

        it 'returns all elements' do
          expect(subject.body).to be_json_eql(3).at_path('count')
          expect(subject.body).to be_json_eql(3).at_path('total')
        end

        it 'returns work packages ordered by priority' do
          prio1_path = api_v3_paths.priority(priority1.id)
          prio2_path = api_v3_paths.priority(priority2.id)

          expect(subject.body).to(be_json_eql(prio2_path.to_json)
                                    .at_path('_embedded/elements/0/_links/priority/href'))
          expect(subject.body).to(be_json_eql(prio1_path.to_json)
                                    .at_path('_embedded/elements/1/_links/priority/href'))
          expect(subject.body).to(be_json_eql(prio1_path.to_json)
                                    .at_path('_embedded/elements/2/_links/priority/href'))
        end

        it 'contains group elements' do
          expect(subject.body).to include_json(expected_group1.to_json).at_path('groups')
          expect(subject.body).to include_json(expected_group2.to_json).at_path('groups')
        end

        context 'displaying sums' do
          let(:query) { { groupBy: 'priority', showSums: 'true' } }
          let(:expected_group1) do
            {
              _links: {
                valueLink: [{
                  href: api_v3_paths.priority(priority1.id)
                }],
                groupBy: {
                  href: api_v3_paths.query_group_by('priority'),
                  title: 'Priority'
                }
              },
              value: priority1.name,
              count: 2,
              sums: {
                estimatedTime: 'PT4H'
              }
            }
          end
          let(:expected_group2) do
            {
              _links: {
                valueLink: [{
                  href: api_v3_paths.priority(priority2.id)
                }],
                groupBy: {
                  href: api_v3_paths.query_group_by('priority'),
                  title: 'Priority'
                }
              },
              value: priority2.name,
              count: 1,
              sums: {
                estimatedTime: 'PT2H'
              }
            }
          end

          it 'contains extended group elements' do
            expect(subject.body).to include_json(expected_group1.to_json).at_path('groups')
            expect(subject.body).to include_json(expected_group2.to_json).at_path('groups')
          end
        end
      end

      describe 'displaying sums' do
        let(:query) { { showSums: 'true' } }
        let(:work_packages) do
          [
            FactoryBot.create(:work_package, project: project, estimated_hours: 1),
            FactoryBot.create(:work_package, project: project, estimated_hours: 2)
          ]
        end

        it 'returns both elements' do
          expect(subject.body).to be_json_eql(2).at_path('count')
          expect(subject.body).to be_json_eql(2).at_path('total')
        end

        it 'contains the sum element' do
          expected = {
            estimatedTime: 'PT3H'
          }

          expect(subject.body).to be_json_eql(expected.to_json).at_path('totalSums')
        end
      end
    end
  end

  describe '#post' do
    let(:permissions) { [:add_work_packages, :view_project] }
    let(:status) { FactoryBot.build(:status, is_default: true) }
    let(:priority) { FactoryBot.build(:priority, is_default: true) }
    let(:parameters) do
      {
        subject: 'new work packages',
        _links: {
          type: {
            href: api_v3_paths.type(project.types.first.id)
          }
        }
      }
    end

    before do
      status.save!
      priority.save!

      FactoryBot.create(:user_preference, user: current_user, others: { no_self_notified: false })
      post path, parameters.to_json, 'CONTENT_TYPE' => 'application/json'
      perform_enqueued_jobs
    end

    context 'notifications' do
      let(:permissions) { [:add_work_packages, :view_project, :view_work_packages] }

      it 'sends a mail by default' do
        expect(DeliverWorkPackageNotificationJob).to have_been_enqueued
      end

      context 'without notifications' do
        let(:path) { "#{api_v3_paths.work_packages_by_project(project.id)}?notify=false" }

        it 'should not send a mail' do
          expect(DeliverWorkPackageNotificationJob).not_to have_been_enqueued
        end
      end

      context 'with notifications' do
        let(:path) { "#{api_v3_paths.work_packages_by_project(project.id)}?notify=true" }

        it 'should send a mail' do
          expect(DeliverWorkPackageNotificationJob).to have_been_enqueued
        end
      end
    end

    it 'should return Created(201)' do
      expect(last_response.status).to eq(201)
    end

    it 'should create a work package' do
      expect(WorkPackage.all.count).to eq(1)
    end

    it 'should use the given parameters' do
      expect(WorkPackage.first.subject).to eq(parameters[:subject])
    end

    context 'no permissions' do
      let(:current_user) { FactoryBot.create(:user) }

      it 'should hide the endpoint' do
        expect(last_response.status).to eq(404)
      end
    end

    context 'view_project permission' do
      # Note that this just removes the add_work_packages permission
      # view_project is actually provided by being a member of the project
      let(:permissions) { [:view_project] }

      it 'should point out the missing permission' do
        expect(last_response.status).to eq(403)
      end
    end

    context 'empty parameters' do
      let(:parameters) { {} }

      it_behaves_like 'constraint violation' do
        let(:message) { "Subject can't be blank" }
      end

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end

    context 'bogus parameters' do
      let(:parameters) do
        {
          bogus: 'bogus',
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            }
          }
        }
      end

      it_behaves_like 'constraint violation' do
        let(:message) { "Subject can't be blank" }
      end

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end

    context 'invalid value' do
      let(:parameters) do
        {
          subject: nil,
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            }
          }
        }
      end

      it_behaves_like 'constraint violation' do
        let(:message) { "Subject can't be blank" }
      end

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end
  end
end
