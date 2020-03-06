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

describe ::API::V3::Activities::ActivityRepresenter do
  include API::Bim::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u)
        .to receive(:allowed_to?) do |checked_permission, project|
        project == work_package.project && permissions.include?(checked_permission)
      end
    end
  end
  let(:other_user) { FactoryBot.build_stubbed(:user) }
  let(:work_package) do
    journal.journable.tap do |wp|
      allow(wp)
        .to receive(:bcf_issue)
        .and_return(bcf_topic)
    end
  end
  let(:journal) do
    FactoryBot.build_stubbed(:work_package_journal).tap do |journal|
      allow(journal)
        .to receive(:notes_id)
        .and_return(journal.id)
      allow(journal)
        .to receive(:get_changes)
        .and_return(changes)
      allow(journal)
        .to receive(:bcf_comment)
        .and_return(bcf_comment)
    end
  end
  let(:changes) { { subject: ["first subject", "second subject"] } }
  let(:bcf_topic) do
    FactoryBot.build_stubbed(:bcf_issue_with_comment)
  end
  let(:bcf_comment) { bcf_topic.comments.first }
  let(:permissions) { %i(edit_work_package_notes view_linked_issues) }
  let(:representer) { described_class.new(journal, current_user: current_user) }

  before do
    login_as(current_user)
  end

  subject(:generated) { representer.to_json }

  describe 'type' do
    context 'if a bcf_comment is present' do
      let(:notes) { '' }
      it 'is Activity::BcfComment' do
        is_expected
          .to be_json_eql('Activity::BcfComment'.to_json)
          .at_path('_type')
      end
    end
  end

  describe '_links' do
    describe 'bcfViewpoints' do
      context 'if a viewpoint is present' do
        it_behaves_like 'has a link collection' do
          let(:link) { 'bcfViewpoints' }
          let(:hrefs) do
            [
              {
                href: bcf_v2_1_paths.viewpoint(work_package.project.identifier, bcf_topic.uuid, bcf_topic.viewpoints[0].uuid)
              }
            ]
          end
        end

        context 'if no comment is present' do
          let(:bcf_comment) { nil }

          it_behaves_like 'has no link' do
            let(:link) { 'bcfViewpoints' }
          end
        end

        context 'if no viewpoint is linked' do
          before do
            allow(bcf_comment)
              .to receive(:viewpoint)
              .and_return nil
          end

          it_behaves_like 'has a link collection' do
            let(:link) { 'bcfViewpoints' }
            let(:hrefs) do
              []
            end
          end
        end

        context 'if permission is lacking' do
          let(:permissions) { %i[] }

          it_behaves_like 'has no link' do
            let(:link) { 'bcfViewpoints' }
          end
        end
      end
    end
  end
end
