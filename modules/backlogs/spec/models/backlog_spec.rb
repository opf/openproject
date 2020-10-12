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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Backlog, type: :model do
  let(:project) { FactoryBot.build(:project) }

  before(:each) do
    @feature = FactoryBot.create(:type_feature)
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'story_types'           => [@feature.id.to_s],
                                                                         'task_type'             => '0' })
    @status = FactoryBot.create(:status)
  end

  describe 'Class Methods' do
    describe '#owner_backlogs' do
      describe 'WITH one open version defined in the project' do
        before(:each) do
          @project = project
          @work_packages = [FactoryBot.create(:work_package, subject: 'work_package1', project: @project, type: @feature, status: @status)]
          @version = FactoryBot.create(:version, project: project, work_packages: @work_packages)
          @version_settings = @version.version_settings.create(display: VersionSetting::DISPLAY_RIGHT, project: project)
        end

        it { expect(Backlog.owner_backlogs(@project)[0]).to be_owner_backlog }
      end
    end
  end
end
