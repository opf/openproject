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
require Rails.root.join("db/migrate/20261101094500_rename_ai_text_transform_actions_to_text_actions.rb")

RSpec.describe RenameAITextTransformActionsToTextActions, type: :model do
  let(:migration) { described_class.new }

  def store_setting(name, value)
    Setting.connection.execute("INSERT INTO settings (name, value, updated_at) VALUES ('#{name}', '#{value}', NOW())")
  end

  def setting_values(name)
    Setting.where(name:).pluck(:value)
  end

  before { ActiveRecord::Migration.suppress_messages { migration.down } }

  subject(:migrate) { ActiveRecord::Migration.suppress_messages { migration.up } }

  context "when the renamed setting already exists" do
    before do
      store_setting("ai_text_transform_actions_enabled", "0")
      store_setting("ai_text_actions_enabled", "1")
    end

    it "keeps a single row with the old setting's value" do
      migrate

      expect(setting_values("ai_text_actions_enabled")).to eq(["0"])
      expect(setting_values("ai_text_transform_actions_enabled")).to be_empty
    end
  end

  context "when only the renamed setting exists" do
    before { store_setting("ai_text_actions_enabled", "1") }

    it "keeps it" do
      migrate

      expect(setting_values("ai_text_actions_enabled")).to eq(["1"])
    end
  end
end
