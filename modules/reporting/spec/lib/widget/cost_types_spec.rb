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

RSpec.describe Widget::CostTypes, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:cost_types) { create_list(:cost_type, 2).pluck(:id) }
  let(:options) { { selected_type_id: cost_types.last } }

  subject(:rendered_component) do
    render_component(cost_types, **options)
  end

  it "renders radio group" do
    expect(rendered_component).to have_element :fieldset, role: "radiogroup"
  end

  it "renders 1 checked radio button" do
    expect(rendered_component).to have_checked_field count: 1
  end

  it "renders 2 unchecked radio buttons" do
    expect(rendered_component).to have_unchecked_field count: 2
  end
end
