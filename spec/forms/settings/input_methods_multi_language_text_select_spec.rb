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

RSpec.describe Settings::InputMethods, "#multi_language_text_select", :aggregate_failures, :settings_reset,
               type: :forms do
  include_context "with rendered inline settings form"
  include_context "with locale for testing"

  let(:translations) { { setting_registration_footer: "Registration footer" } }

  subject(:rendered_form) do
    vc_render_inline_settings_form do |settings_form|
      settings_form.multi_language_text_select(name: :registration_footer, current_language: "en")
    end

    page
  end

  it "wires up the language switcher so other languages can be edited and saved" do
    expect(rendered_form).to have_css("[data-controller='admin--multi-lang-text-setting']")
    expect(rendered_form).to have_css("select[data-admin--multi-lang-text-setting-target='select']")
    expect(rendered_form).to have_css(
      "input[type=hidden][data-admin--multi-lang-text-setting-target='langFor'][data-lang='de']",
      visible: :all
    )
    expect(rendered_form).to have_css("textarea[data-admin--multi-lang-text-setting-target='textArea']",
                                      visible: :all)
  end
end
