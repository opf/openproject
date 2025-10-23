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

require "rails_helper"

RSpec.describe Budgets::BudgetItems::InlineCostEditComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:input_name) { "test[field]" }
  let(:input_id) { "test_field" }
  let(:cost_value) { "20.00" }

  subject(:rendered_component) do
    render_component(input_name:, input_id:, cost_value:)
  end

  it "renders 2 buttons" do
    expect(rendered_component).to have_button count: 1, visible: :visible
    expect(rendered_component).to have_button count: 1, visible: :hidden
  end

  it "renders field describedby currency" do
    expect(rendered_component).to have_field "test_field", with: cost_value, described_by: "EUR"
  end
end
