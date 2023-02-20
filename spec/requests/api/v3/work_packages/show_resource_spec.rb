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

require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package resource',
         content_type: :json do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  let(:closed_status) { create(:closed_status) }

  let(:work_package) do
    create(:work_package,
           project_id: project.id,
           description: 'lorem ipsum')
  end
  let(:project) do
    create(:project, identifier: 'test_project', public: false)
  end
  let(:role) { create(:role, permissions:) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }
  let(:current_user) do
    create(:user, member_in_project: project, member_through_role: role)
  end
  let(:unauthorize_user) { create(:user) }
  let(:type) { create(:type) }

  before do
    login_as(current_user)
  end

  describe 'GET /api/v3/work_packages/:id' do
    let(:get_path) { api_v3_paths.work_package work_package.id }

    context 'when acting as a user with permission to view work package' do
      before do
        login_as(current_user)
        get get_path
      end

      it 'responds with 200' do
        expect(last_response.status).to eq(200)
      end

      describe 'response body' do
        subject { last_response.body }

        let!(:other_wp) do
          create(:work_package,
                 project_id: project.id,
                 status: closed_status)
        end
        let(:work_package) do
          create(:work_package,
                 project_id: project.id,
                 description:).tap do |wp|
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
            expect(subject).to have_selector('h1')
            expect(subject).to have_selector('h2')

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
            [create(:work_package,
                    start_date: Date.today,
                    due_date: Date.today + 5.days)]
          end

          it 'has derived dates' do
            expect(subject)
              .to be_json_eql(Date.today.to_json)
                    .at_path('derivedStartDate')

            expect(subject)
              .to be_json_eql((Date.today + 5.days).to_json)
                    .at_path('derivedDueDate')
          end
        end

        describe 'relations' do
          let(:directly_related_wp) do
            create(:work_package, project_id: project.id)
          end
          let(:transitively_related_wp) do
            create(:work_package, project_id: project.id)
          end

          let(:work_package) do
            create(:work_package,
                   project_id: project.id,
                   description: 'lorem ipsum').tap do |wp|
              create(:relation, relation_type: Relation::TYPE_RELATES, from: wp, to: directly_related_wp)
              create(:relation, relation_type: Relation::TYPE_RELATES, from: directly_related_wp, to: transitively_related_wp)
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

        it_behaves_like 'not found',
                        I18n.t('api_v3.errors.not_found.work_package')
      end
    end

    context 'when acting as a user without permission to view work package' do
      before do
        allow(User).to receive(:current).and_return unauthorize_user
        get get_path
      end

      it_behaves_like 'not found',
                      I18n.t('api_v3.errors.not_found.work_package')
    end

    context 'when acting as an anonymous user' do
      before do
        allow(User).to receive(:current).and_return User.anonymous
        get get_path
      end

      it_behaves_like 'not found',
                      I18n.t('api_v3.errors.not_found.work_package')
    end
  end

  describe 'GET /api/v3/work_packages/:id?timestamps=' do
    let(:get_path) { "#{api_v3_paths.work_package(work_package.id)}?timestamps=#{timestamps.map(&:to_s).join(',')}" }

    describe 'response body' do
      subject do
        login_as current_user
        get get_path
        last_response.body
      end

      context 'when providing timestamps' do
        let(:timestamps) { [Timestamp.parse('2015-01-01T00:00:00Z'), Timestamp.now] }
        let(:baseline_time) { timestamps.first.to_time }

        let(:work_package) do
          new_work_package = create(:work_package, subject: "The current work package", project:)
          new_work_package.update_columns created_at: baseline_time - 1.day
          new_work_package
        end
        let(:original_journal) do
          create_journal(journable: work_package, timestamp: baseline_time - 1.day,
                         version: 1,
                         attributes: { subject: "The original work package" })
        end
        let(:current_journal) do
          create_journal(journable: work_package, timestamp: 1.day.ago,
                         version: 2,
                         attributes: { subject: "The current work package" })
        end

        def create_journal(journable:, version:, timestamp:, attributes: {})
          work_package_attributes = work_package.attributes.except("id")
          journal_attributes = work_package_attributes \
              .extract!(*Journal::WorkPackageJournal.attribute_names) \
              .symbolize_keys.merge(attributes)
          create(:work_package_journal, version:,
                                        journable:, created_at: timestamp, updated_at: timestamp,
                                        data: build(:journal_work_package_journal, journal_attributes))
        end

        before do
          WorkPackage.destroy_all
          work_package
          Journal.destroy_all
          original_journal
          current_journal
        end

        it 'responds with 200' do
          expect(subject && last_response.status).to eq(200)
        end

        it 'embeds the baselineAttributes' do
          expect(subject)
            .to be_json_eql("The original work package".to_json)
            .at_path('_embedded/baselineAttributes/subject')
        end

        it 'does not embed the attributes in baselineAttributes if they are the same as the current attributes' do
          expect(subject)
            .not_to have_json_path('_embedded/baselineAttributes/description')
        end

        it 'embeds the attributesByTimestamp' do
          expect(subject)
            .to be_json_eql("The original work package".to_json)
            .at_path("_embedded/attributesByTimestamp/0/subject")
          expect(subject)
            .to have_json_path("_embedded/attributesByTimestamp/1")
        end

        it 'does not embed the attributes in attributesByTimestamp if they are the same as the current attributes' do
          expect(subject)
            .not_to have_json_path("_embedded/attributesByTimestamp/0/description")
          expect(subject)
            .not_to have_json_path("_embedded/attributesByTimestamp/1/description")
        end

        it 'has the current attributes as attributes' do
          expect(subject)
            .to be_json_eql("The current work package".to_json)
            .at_path('subject')
        end

        it 'has an embedded link to the baseline work package' do
          expect(subject)
            .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.first).to_json)
            .at_path('_embedded/attributesByTimestamp/0/_links/self/href')
        end

        it 'has the absolute timestamps within the self link' do
          Timecop.freeze do
            expect(subject)
              .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: timestamps.map(&:absolute)).to_json)
              .at_path('_links/self/href')
          end
        end
      end
    end
  end
end
