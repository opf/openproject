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

require "rails_helper"

RSpec.describe Messages::AcceptedSolutionIconComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(kind:)) }

  let(:kind) { described_class::REPLY }

  it "names the checkmark for assistive technology" do
    expect(rendered_component).to have_role(:img, accessible_name: "Accepted solution")
  end

  it "titles an HTML element around the checkmark, since browsers show no tooltip for an SVG's title attribute" do
    expect(rendered_component).to have_css("span[title='Accepted solution'] > svg")
  end

  it "draws an outline checkmark, like the topic list's pin and lock flags" do
    expect(rendered_component).to have_css("svg.octicon-check-circle")
  end

  context "for a topic" do
    let(:kind) { described_class::TOPIC }

    it "names the checkmark after the topic's state" do
      expect(rendered_component).to have_role(:img, accessible_name: "With accepted solution")
    end
  end
end
