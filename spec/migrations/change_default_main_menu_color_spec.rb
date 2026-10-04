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
require Rails.root.join("db/migrate/20250627121119_change_default_main_menu_color.rb")

RSpec.describe ChangeDefaultMainMenuColor, type: :model do
  context "when migrating up" do
    context "with the standard color defined" do
      before do
        create(:design_color, variable: "main-menu-bg-color", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_MAIN_MENU_COLOR)
      end

      # Silencing migration logs, since we are not interested in that during testing
      subject { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

      it "replaces the value'" do
        expect { subject }.not_to change(DesignColor, :count)
        expect(DesignColor.find_by(variable: "main-menu-bg-color").hexcode).to eq "#FFFFFF"
      end
    end

    context "with a custom color defined" do
      before do
        create(:design_color, variable: "main-menu-bg-color", hexcode: "#ABC123")
      end

      # Silencing migration logs, since we are not interested in that during testing
      subject { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

      it "keeps the custom the value'" do
        expect { subject }.not_to change(DesignColor, :count)
        expect(DesignColor.find_by(variable: "main-menu-bg-color").hexcode).to eq "#ABC123"
      end
    end
  end

  context "when migrating down" do
    context "with the standard color defined" do
      before do
        create(:design_color, variable: "main-menu-bg-color", hexcode: "#FFFFFF")
      end

      # Silencing migration logs, since we are not interested in that during testing
      subject { ActiveRecord::Migration.suppress_messages { described_class.new.down } }

      it "replaces the value'" do
        expect { subject }.not_to change(DesignColor, :count)
        expect(DesignColor.find_by(variable: "main-menu-bg-color").hexcode).to eq OpenProject::CustomStyles::ColorThemes::DEPRECATED_MAIN_MENU_COLOR
      end
    end

    context "with a custom color defined" do
      before do
        create(:design_color, variable: "main-menu-bg-color", hexcode: "#ABC123")
      end

      # Silencing migration logs, since we are not interested in that during testing
      subject { ActiveRecord::Migration.suppress_messages { described_class.new.down } }

      it "keeps the custom the value'" do
        expect { subject }.not_to change(DesignColor, :count)
        expect(DesignColor.find_by(variable: "main-menu-bg-color").hexcode).to eq "#ABC123"
      end
    end
  end
end
