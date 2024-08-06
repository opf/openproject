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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require Rails.root.join("db/migrate/20220428071221_restore_defaults_on_empty_settings.rb")

RSpec.describe RestoreDefaultsOnEmptySettings, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject(:run_migration) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  shared_examples_for "a successful migration of an empty setting" do
    let(:setting_name) { raise "define me!" }
    let(:old_value) { nil }
    let(:expected_value) { raise "define me!" }

    before do
      Setting.create name: setting_name, value: ""
    end

    it "migrates the value to the expected value" do
      expect { run_migration }
        .to change { Setting.find_by(name: setting_name).value }
        .from(old_value)
        .to(expected_value)
    end

    it "does not raise a type error" do
      expect { run_migration }.not_to raise_error
    end
  end

  context "with an empty setting which must be an array" do
    it_behaves_like "a successful migration of an empty setting" do
      let(:setting_name) { "apiv3_cors_origins" }
      let(:expected_value) { [] }
    end
  end

  context "with an empty setting which must be a string" do
    it_behaves_like "a successful migration of an empty setting" do
      let(:setting_name) { "default_language" }
      let(:old_value) { "" }
      let(:expected_value) { "en" }
    end
  end

  context "with an empty setting which must be a boolean" do
    it_behaves_like "a successful migration of an empty setting" do
      let(:setting_name) { "smtp_enable_starttls_auto" }
      let(:expected_value) { false }
    end
  end

  context "with an empty setting which is not writable" do
    let(:setting_name) { "smtp_openssl_verify_mode" }

    it "deletes the setting from the database" do
      setting = Setting.new name: setting_name
      setting.set_value!("", force: true)
      setting.save!

      run_migration
      expect(Setting.where(id: setting.id)).not_to exist
      expect(Setting.send(setting_name)).to eq("peer")
    end
  end
end
