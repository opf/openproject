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
require Rails.root.join("db/migrate/20240307102541_reduce_configurable_design_variables.rb")

RSpec.describe ReduceConfigurableDesignVariables, type: :model do
  context "when migrating up" do
    before do
      create(:design_color, variable: "alternative-color")
      create(:design_color, variable: "primary-color")
      create(:design_color, variable: "primary-color-dark")
      create(:design_color, variable: "content-link-color")
    end

    # Silencing migration logs, since we are not interested in that during testing
    subject { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

    it "removes the obsolete variables and renames 'alternative-color'" do
      expect { subject }
        .to change(DesignColor, :count).from(4).to(2)

      expect(DesignColor.find_by(variable: "primary-button-color")).not_to be_nil
      expect(DesignColor.find_by(variable: "accent-color")).not_to be_nil
      expect(DesignColor.find_by(variable: "primary-color")).to be_nil
      expect(DesignColor.find_by(variable: "primary-color-dark")).to be_nil
      expect(DesignColor.find_by(variable: "alternative-color")).to be_nil
      expect(DesignColor.find_by(variable: "content-link-color")).to be_nil
    end
  end

  context "when migrating down" do
    before do
      create(:design_color, variable: "primary-button-color")
      create(:design_color, variable: "accent-color")
    end

    # Silencing migration logs, since we are not interested in that during testing
    subject { ActiveRecord::Migration.suppress_messages { described_class.new.down } }

    it "re-creates the removed variables and reverts the renaming" do
      expect { subject }
        .to change(DesignColor, :count).from(2).to(4)

      expect(DesignColor.find_by(variable: "primary-button-color")).to be_nil
      expect(DesignColor.find_by(variable: "accent-color")).to be_nil
      expect(DesignColor.find_by(variable: "primary-color")).not_to be_nil
      expect(DesignColor.find_by(variable: "primary-color-dark")).not_to be_nil
      expect(DesignColor.find_by(variable: "alternative-color")).not_to be_nil
      expect(DesignColor.find_by(variable: "content-link-color")).not_to be_nil
    end
  end
end
