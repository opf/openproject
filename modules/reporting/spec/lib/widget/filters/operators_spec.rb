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

RSpec.describe Widget::Filters::Operators, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:filter) { CostQuery::Filter::Subject.new }
  let(:options) { {} }

  subject(:rendered_component) do
    render_component(filter, **options)
  end

  it "renders component" do
    expect(rendered_component).to have_css ".advanced-filters--filter-operator"
  end

  it "renders label for accessibility" do
    expect(rendered_component).to have_element :label, text: "Subject Operator", class: "sr-only"
  end

  context "with a string operators filter" do
    it "renders select" do
      expect(rendered_component).to have_select options: ["doesn't contain", "contains", "is", "is not"]
    end
  end

  context "with a multi-choice filter" do
    let(:filter) { CostQuery::Filter::MultiChoice.new }

    it "renders hidden select" do
      expect(rendered_component).to have_select options: ["is"], visible: :hidden
    end
  end
end
