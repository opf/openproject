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

RSpec.describe Primer::OpenProject::Forms::ColorSelect, type: :forms do
  include_context "with rendered inline form"

  let(:model) { build_stubbed(:status) }
  let(:hidden_color_field) { "input[type=hidden][name='status[color_id]']" }

  def render_color_select(**)
    vc_render_inline_form do |form|
      form.color_select_list(name: :color_id, label: "Color", **)
    end
  end

  it "submits the color through an enabled hidden field" do
    render_color_select

    expect(page).to have_css("#{hidden_color_field}:not([disabled])", visible: :all)
  end

  it "disables the hidden field when the input is disabled, so no color is submitted" do
    render_color_select(disabled: true)

    expect(page).to have_css("#{hidden_color_field}[disabled]", visible: :all)
  end
end
