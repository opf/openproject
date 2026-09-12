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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Automations::Triggers::Manual do
  describe ".key" do
    it "derives from the class name" do
      expect(described_class.key).to eq(:manual)
    end
  end

  describe ".human_name" do
    it "is the translated label" do
      expect(described_class.human_name).to eq("Manual button click")
    end

    it "falls back to the class name when no translation exists" do
      expect(Automations::Triggers::Base.human_name).to eq("Base")
    end
  end

  describe "#human_name" do
    it "delegates to the class" do
      expect(described_class.new.human_name).to eq("Manual button click")
    end
  end

  describe "type" do
    let(:automation) { build(:automation) }

    it "accepts a registered trigger type" do
      trigger = automation.triggers.detect { |t| t.is_a?(described_class) }

      expect(trigger).to be_valid
    end

    it "rejects a type that is not registered" do
      trigger = automation.triggers.first
      trigger.type = "Automations::Triggers::Base"

      expect(trigger).not_to be_valid
      expect(trigger.errors.symbols_for(:type)).to include(:inclusion)
    end

    it "makes the automation invalid" do
      automation.triggers.first.type = "Automations::Triggers::Base"

      expect(automation).not_to be_valid
    end
  end
end
