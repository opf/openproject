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
require Rails.root.join("db/migrate/20261102040000_remove_ai_text_actions_enabled_setting.rb")

RSpec.describe RemoveAITextActionsEnabledSetting, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let!(:text_action) { create(:ai_text_action, active: true) }

  def store_setting(value)
    Setting.connection.execute(
      "INSERT INTO settings (name, value, updated_at) " \
      "VALUES ('ai_text_actions_enabled', '#{value}', NOW())"
    )
  end

  def setting_row_count
    Setting.where(name: "ai_text_actions_enabled").count
  end

  context "without a stored setting and without an environment override" do
    it "deactivates all actions" do
      migrate

      expect(text_action.reload).not_to be_active
    end
  end

  context "with the setting stored as true" do
    before { store_setting("1") }

    it "keeps the actions active and removes the row" do
      migrate

      expect(text_action.reload).to be_active
      expect(setting_row_count).to eq(0)
    end
  end

  context "with the setting stored as false" do
    before { store_setting("0") }

    it "deactivates all actions and removes the row" do
      migrate

      expect(text_action.reload).not_to be_active
      expect(setting_row_count).to eq(0)
    end
  end

  context "without a stored setting but with a truthy environment override" do
    {
      "OPENPROJECT_AI__TEXT__TRANSFORM__ACTIONS__ENABLED" => "true",
      "OPENPROJECT_AI_TEXT_TRANSFORM_ACTIONS_ENABLED" => "true",
      "OPENPROJECT_AI__TEXT__ACTIONS__ENABLED" => "yes",
      "OPENPROJECT_AI_TEXT_ACTIONS_ENABLED" => "yes"
    }.each do |variable, value|
      it "keeps the actions active for #{variable}" do
        with_env(variable => value) { migrate }

        expect(text_action.reload).to be_active
      end
    end
  end

  context "with the setting stored as true and a falsy environment override" do
    before { store_setting("1") }

    it "deactivates all actions" do
      with_env("OPENPROJECT_AI__TEXT__ACTIONS__ENABLED" => "false") { migrate }

      expect(text_action.reload).not_to be_active
    end
  end

  context "with the setting stored as true and an empty, null or symbol false environment override" do
    before { store_setting("1") }

    ["", "null", ":false"].each do |value|
      it "deactivates all actions for #{value.inspect}" do
        with_env("OPENPROJECT_AI__TEXT__ACTIONS__ENABLED" => value) { migrate }

        expect(text_action.reload).not_to be_active
      end
    end
  end

  context "without a stored setting and with a numeric truthy environment override" do
    it "keeps the actions active" do
      with_env("OPENPROJECT_AI_TEXT_ACTIONS_ENABLED" => "1") { migrate }

      expect(text_action.reload).to be_active
    end
  end

  context "without a stored setting and with a falsy environment override" do
    it "deactivates all actions" do
      with_env("OPENPROJECT_AI__TEXT__TRANSFORM__ACTIONS__ENABLED" => "false") { migrate }

      expect(text_action.reload).not_to be_active
    end
  end
end
