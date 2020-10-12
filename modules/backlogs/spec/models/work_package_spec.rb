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

describe WorkPackage, type: :model do
  describe '#backlogs_types' do
    it 'should return all the ids of types that are configures to be considered backlogs types' do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'story_types' => [1], 'task_type' => 2 })

      expect(WorkPackage.backlogs_types).to match_array([1, 2])
    end

    it 'should return an empty array if nothing is defined' do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({})

      expect(WorkPackage.backlogs_types).to eq([])
    end

    it 'should reflect changes to the configuration' do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'story_types' => [1], 'task_type' => 2 })
      expect(WorkPackage.backlogs_types).to match_array([1, 2])

      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'story_types' => [3], 'task_type' => 4 })
      expect(WorkPackage.backlogs_types).to match_array([3, 4])
    end
  end
end
