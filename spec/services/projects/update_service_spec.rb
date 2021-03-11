#-- encoding: UTF-8

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
require 'services/base_services/behaves_like_update_service'

describe Projects::UpdateService, type: :model do
  it_behaves_like 'BaseServices update service' do
    let!(:model_instance) do
      FactoryBot.build_stubbed(:project, status: project_status).tap do |_p|
        project_status.clear_changes_information
      end
    end
    let(:project_status) { FactoryBot.build_stubbed(:project_status) }

    it 'sends an update notification' do
      expect(OpenProject::Notifications)
        .to(receive(:send))
        .with('project_updated', project: model_instance)

      subject
    end

    context 'if the identifier is altered' do
      let(:call_attributes) { { identifier: 'Some identifier' } }

      before do
        allow(model_instance)
          .to(receive(:changes))
          .and_return('identifier' => %w(lorem ipsum))
      end

      it 'sends the notification' do
        expect(OpenProject::Notifications)
          .to(receive(:send))
          .with('project_updated', project: model_instance)
        expect(OpenProject::Notifications)
          .to(receive(:send))
          .with('project_renamed', project: model_instance)

        subject
      end
    end

    context 'if the parent is altered' do
      before do
        allow(model_instance)
          .to(receive(:changes))
          .and_return('parent_id' => [nil, 5])
      end

      it 'updates the versions associated with the work packages' do
        expect(WorkPackage)
          .to(receive(:update_versions_from_hierarchy_change))
          .with(model_instance)

        subject
      end
    end

    context 'if the project status is altered' do
      before do
        allow(project_status)
          .to(receive(:changed?))
          .and_return(true)
      end

      it 'persists the changes' do
        expect(project_status).to receive(:save)

        subject
      end
    end
  end
end
