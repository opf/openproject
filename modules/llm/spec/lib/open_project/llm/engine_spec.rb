# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# This program is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
require_module_spec_helper

RSpec.describe OpenProject::Llm::Engine do
  describe "semantic_search_results_limit setting" do
    let(:definition) { Settings::Definition[:semantic_search_results_limit] }

    it "is an integer setting, hidden from the administration UI, defaulting to the model's SEARCH_LIMIT" do
      expect(definition.format).to eq(:integer)
      expect(definition).not_to be_writable
      expect(definition.default).to eq(WorkPackageEmbedding::SEARCH_LIMIT)
    end

    it "is overridable via environment variable for the instance" do
      expect(definition.possible_env_names).to include("OPENPROJECT_SEMANTIC_SEARCH_RESULTS_LIMIT")
    end

    it "reads the default when nothing is configured" do
      expect(Setting.semantic_search_results_limit).to eq(WorkPackageEmbedding::SEARCH_LIMIT)
    end
  end
end
