# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require Rails.root.join("db/migrate/20261109232225_delete_pre_release_ai_text_actions.rb")

RSpec.describe DeletePreReleaseAITextActions, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  before do
    create(:ai_text_action)
    create(:ai_text_action, :for_specific_types)
  end

  it "deletes all actions with their type assignments" do
    migrate

    expect(AI::TextAction.count).to eq(0)
    expect(AI::TextActionType.count).to eq(0)
  end
end
