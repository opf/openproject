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
require_module_spec_helper

RSpec.describe Projects::Settings::CostTypes::IndexComponent, type: :component do
  shared_let(:admin) { create(:admin) }
  let(:project) { create(:project) }

  current_user { admin }

  subject(:rendered_component) { render_inline(described_class.new(project:, cost_types:)) }

  context "with cost types" do
    let!(:cost_type) { create(:cost_type, name: "Consulting") }
    let(:cost_types) { CostType.where(id: cost_type.id) }

    it_behaves_like "rendering Box", row_count: 1

    it "renders the cost types header" do
      expect(rendered_component).to have_css(".Box-header") do |header|
        expect(header).to have_heading(CostType.model_name.human(count: 2))
      end
    end

    it "renders a row per cost type" do
      expect(rendered_component).to have_css(".Box-row", text: "Consulting")
    end
  end

  context "without cost types" do
    let(:cost_types) { CostType.none }

    it_behaves_like "rendering an empty Border Box List",
                    heading: I18n.t("cost_types.settings.cost_types.heading")
  end
end
