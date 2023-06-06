# frozen_string_literal: true

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

RSpec.describe BasicData::Backlogs::SettingSeeder do
  subject(:setting_seeder) { described_class.new(basic_seed_data) }

  context 'with standard edition' do
    include_context 'with basic seed data', edition: 'standard'

    it 'configures Setting.plugin_openproject_backlogs' do
      setting_seeder.seed!

      type_feature = basic_seed_data.find_reference(:default_type_feature)
      type_epic = basic_seed_data.find_reference(:default_type_epic)
      type_user_story = basic_seed_data.find_reference(:default_type_user_story)
      type_bug = basic_seed_data.find_reference(:default_type_bug)
      type_task = basic_seed_data.find_reference(:default_type_task)

      expect(Setting.plugin_openproject_backlogs).to match(
        "points_burn_direction" => "up",
        "story_types" => contain_exactly(type_feature.id, type_epic.id, type_user_story.id, type_bug.id),
        "task_type" => type_task.id,
        "wiki_template" => ""
      )
    end
  end

  context 'with BIM edition' do
    include_context 'with basic seed data', edition: 'bim'

    it 'configures Setting.plugin_openproject_backlogs' do
      setting_seeder.seed!

      type_task = basic_seed_data.find_reference(:default_type_task)

      expect(Setting.plugin_openproject_backlogs).to match(
        "points_burn_direction" => "up",
        "story_types" => [],
        "task_type" => type_task.id,
        "wiki_template" => ""
      )
    end
  end
end
