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

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  include API::V3::Utilities::PathHelper
  include API::Bim::Utilities::PathHelper

  let(:project) do
    work_package.project
  end
  let(:permissions) { %i[view_linked_issues view_work_packages] }
  let(:user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u)
        .to receive(:allowed_to?) do |queried_permissison, queried_project|
        queried_project == work_package.project &&
          permissions.include?(queried_permissison)
      end
    end
  end
  let(:bcf_topic) do
    FactoryBot.build_stubbed(:bcf_issue_with_comment)
  end
  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package, bcf_issue: bcf_topic)
  end
  let(:representer) do
    described_class.new(work_package,
                        current_user: user,
                        embed_links: true)
  end

  before(:each) do
    login_as user
  end

  subject(:generated) { representer.to_json }

  include_context 'eager loaded work package representer'

  describe 'with BCF issues' do
    it "contains viewpoints" do
      is_expected.to be_json_eql([
        {
          file_name: bcf_topic.viewpoints.first.attachments.first.filename,
          id: bcf_topic.viewpoints.first.attachments.first.id
        }
      ].to_json)
        .including('id')
        .at_path('bcf/viewpoints/')
    end
  end

  describe '_links' do
    describe 'bcfTopic' do
      context 'if a topic is present' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'bcfTopic' }
          let(:href) { "/api/bcf/2.1/projects/#{project.identifier}/topics/#{bcf_topic.uuid}" }
        end
      end

      context 'if no topic is present' do
        let(:bcf_topic) { nil }

        it_behaves_like 'has no link' do
          let(:link) { 'bcfTopic' }
        end
      end

      context 'if permission is lacking' do
        let(:permissions) { %i[view_work_packages] }

        it_behaves_like 'has no link' do
          let(:link) { 'bcfTopic' }
        end
      end
    end

    describe 'bcfViewpoints' do
      context 'if a viewpoint is present' do
        it_behaves_like 'has a link collection' do
          let(:link) { 'bcfViewpoints' }
          let(:hrefs) do
            [
              {
                href: bcf_v2_1_paths.viewpoint(project.identifier, bcf_topic.uuid, bcf_topic.viewpoints[0].uuid)
              }
            ]
          end
        end

        context 'if no topic is present' do
          let(:bcf_topic) { nil }

          it_behaves_like 'has no link' do
            let(:link) { 'bcfViewpoints' }
          end
        end

        context 'if no viewpoint is present' do
          before do
            allow(bcf_topic)
              .to receive(:viewpoints)
              .and_return []
          end

          it_behaves_like 'has a link collection' do
            let(:link) { 'bcfViewpoints' }
            let(:hrefs) do
              []
            end
          end
        end

        context 'if permission is lacking' do
          let(:permissions) { %i[view_work_packages] }

          it_behaves_like 'has no link' do
            let(:link) { 'bcfViewpoints' }
          end
        end
      end
    end
  end
end
