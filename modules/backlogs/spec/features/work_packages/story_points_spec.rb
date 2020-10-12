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

describe 'Work packages having story points', type: :feature, js: true do
  before do
    allow(User).to receive(:current).and_return current_user
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return('points_burn_direction' => 'down',
                                                                       'wiki_template'         => '',
                                                                       'card_spec'             => 'Sattleford VM-5040',
                                                                       'story_types'           => [story_type.id.to_s],
                                                                       'task_type'             => task_type.id.to_s)
  end

  let(:current_user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project,
                                     enabled_module_names: %w(work_package_tracking backlogs)) }
  let(:status) { FactoryBot.create :default_status }
  let(:story_type) { FactoryBot.create(:type_feature) }
  let(:task_type) { FactoryBot.create(:type_feature) }

  describe 'showing the story points on the work package show page' do
    let(:story_points) { 42 }
    let(:story_with_sp) {
      FactoryBot.create(:story,
                         type: story_type,
                         author: current_user,
                         project: project,
                         status: status,
                         story_points: story_points)
    }

    it 'should be displayed' do
      wp_page = Pages::FullWorkPackage.new(story_with_sp)

      wp_page.visit!
      wp_page.expect_subject

      wp_page.expect_attributes :storyPoints => story_points

      wp_page.ensure_page_loaded
    end
  end
end
