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

RSpec.describe BasicData::SettingSeeder do
  include_context "with basic seed data"

  subject(:setting_seeder) { described_class.new(basic_seed_data) }

  let(:new_project_role) { basic_seed_data.find_reference(:default_role_project_admin) }
  let(:closed_status) { basic_seed_data.find_reference(:default_status_closed) }

  it "applies initial settings" do
    expect(setting_seeder).to be_applicable

    setting_seeder.seed!

    expect(setting_seeder).not_to be_applicable
    Setting.where(name: %w(commit_fix_status_id new_project_user_role_id)).delete_all
    expect(setting_seeder).to be_applicable

    setting_seeder.seed!

    expect(setting_seeder).not_to be_applicable
    expect(Setting.commit_fix_status_id).to eq closed_status.id
    expect(Setting.new_project_user_role_id).to eq new_project_role.id
  end

  it "does not override existing settings" do
    setting_seeder.seed!

    Setting.commit_fix_status_id = 1337
    Setting.where(name: "new_project_user_role_id").delete_all

    setting_seeder.seed!

    expect(Setting.commit_fix_status_id).to eq 1337
    expect(Setting.new_project_user_role_id).to eq new_project_role.id
  end

  it "does not seed settings whose default value is undefined" do
    setting_seeder.seed!

    names_of_undefined_settings = Settings::Definition.all.values.select { _1.value == nil }.map(&:name)
    # these ones are special as their value is set based on database ids
    names_of_undefined_settings -= ["new_project_user_role_id", "commit_fix_status_id"]
    expect(Setting.where(name: names_of_undefined_settings).pluck(:name)).to be_empty
  end

  context "with I18n.locale set" do
    before do
      I18n.with_locale "ja" do
        setting_seeder.seed!
      end
    end

    it "sets default language to the current locale" do
      expect(Setting.default_language).to eq("ja")
    end

    it "adds current locale to Setting.available_languages" do
      expect(Setting.available_languages).to include("ja")
    end
  end
end
