#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::WorkPackages::Form::WorkPackageSchemaRepresenter do
  let(:work_package) { FactoryGirl.build(:work_package) }
  let(:current_user) {
    FactoryGirl.build(:user, member_in_project: work_package.project)
  }
  let(:representer)  { described_class.new(work_package, current_user: current_user) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe 'schema' do
      shared_examples_for 'schema property' do |path, type, required, writable|
        it { is_expected.to have_json_path(path) }

        it { is_expected.to be_json_eql(type.to_json).at_path("#{path}/type") }

        it 'has valid required value' do
          required_path = "#{path}/required"

          if required.nil?
            is_expected.not_to have_json_path(required_path)
          else
            is_expected.to be_json_eql(required.to_json).at_path(required_path)
          end
        end

        it 'has valid writable value' do
          writable_path = "#{path}/writable"

          if writable.nil?
            is_expected.not_to have_json_path(writable_path)
          else
            is_expected.to be_json_eql(writable.to_json).at_path(writable_path)
          end
        end
      end

      shared_examples_for 'linked property' do |property_name, type|
        it { is_expected.to have_json_path(property_name) }

        it { is_expected.to be_json_eql(type.to_json).at_path("#{property_name}/type") }

        it { is_expected.to have_json_path("#{property_name}/_links") }

        it { is_expected.to have_json_path("#{property_name}/_links/allowedValues") }
      end

      shared_examples_for 'linked with href' do |property_name|
        let(:path) { "#{property_name}/_links/allowedValues/href" }

        it { is_expected.to be_json_eql(href).at_path(path) }
      end

      describe '_type' do
        it_behaves_like 'schema property', '_type', 'MetaType', true, false
      end

      describe 'lock version' do
        it_behaves_like 'schema property', 'lockVersion', 'Integer', true, false
      end

      describe 'subject' do
        it_behaves_like 'schema property', 'subject', 'String'
      end

      describe 'status' do
        shared_examples_for 'contains statuses' do
          it_behaves_like 'linked property', 'status', 'Status'

          it 'contains valid links to statuses' do
            status_links = statuses.map do |status|
              { href: "/api/v3/statuses/#{status.id}", title: status.name }
            end

            is_expected.to be_json_eql(status_links.to_json).at_path('status/_links/allowedValues')
          end

          it 'embeds statuses' do
            embedded_statuses = statuses.map do |status|
              {
                _links: {
                  self: {
                    href: "/api/v3/statuses/#{status.id}",
                    title: status.name
                  }
                },
                _type: 'Status',
                id: status.id,
                name: status.name,
                defaultDoneRatio: status.default_done_ratio,
                isClosed: status.is_closed,
                isDefault: status.is_default,
                position: status.position
              }
            end

            is_expected.to be_json_eql(embedded_statuses.to_json)
                           .at_path('status/_embedded/allowedValues')
          end
        end

        context 'w/o allowed statuses' do
          before { allow(work_package).to receive(:new_statuses_allowed_to).and_return([]) }

          it_behaves_like 'contains statuses' do
            let(:statuses) { [] }
          end
        end

        context 'with allowed statuses' do
          let(:statuses) { FactoryGirl.build_list(:status, 3) }

          before { allow(work_package).to receive(:new_statuses_allowed_to).and_return(statuses) }

          it_behaves_like 'contains statuses'
        end
      end

      describe 'responsible and assignee' do
        let(:base_href) { "/api/v3/projects/#{work_package.project.id}" }

        describe 'assignee' do
          it_behaves_like 'linked property', 'assignee', 'User'

          it_behaves_like 'linked with href', 'assignee' do
            let(:href) { "#{base_href}/available_assignees".to_json }
          end
        end

        describe 'responsible' do
          it_behaves_like 'linked property', 'responsible', 'User'

          it_behaves_like 'linked with href', 'responsible' do
            let(:href) { "#{base_href}/available_responsibles".to_json }
          end
        end
      end
    end
  end
end
