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

require "spec_helper"

RSpec.describe AdminHelper do
  describe ".ai_landing_path" do
    subject(:path) { described_class.ai_landing_path }

    context "with the LLM connection active", with_flag: { llm_connection: true, ai_text_actions: true } do
      it { is_expected.to eq("/admin/llm_connection") }
    end

    context "with only text actions active", with_flag: { llm_connection: false, ai_text_actions: true } do
      it { is_expected.to eq("/admin/text_actions") }
    end

    context "with no flag active", with_flag: { llm_connection: false, ai_text_actions: false } do
      it { is_expected.to eq("/admin/mcp_configurations") }
    end
  end

  describe "the Artificial Intelligence menu item" do
    subject(:url) do
      Redmine::MenuManager.items(:admin_menu).find { |item| item.name == :ai }.url
    end

    context "with the LLM connection active", with_flag: { llm_connection: true } do
      it { is_expected.to eq("/admin/llm_connection") }
    end

    context "with only text actions active", with_flag: { llm_connection: false, ai_text_actions: true } do
      it { is_expected.to eq("/admin/text_actions") }
    end

    context "with no flag active", with_flag: { llm_connection: false, ai_text_actions: false } do
      it { is_expected.to eq("/admin/mcp_configurations") }
    end
  end
end
