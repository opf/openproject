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

RSpec.describe Admin::Settings::APISettingsForm, type: :forms do
  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", model: false, scope: :settings } }

  subject(:rendered_form) do
    vc_render_form
    page
  end

  it "renders", :aggregate_failures do
    expect(rendered_form).to have_field "Enable API tokens", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[api_tokens_enabled]"
    end

    expect(rendered_form).to have_field "Maximum API page size", type: :number do |field|
      expect(field["name"]).to eq "settings[apiv3_max_page_size]"
    end

    expect(rendered_form).to have_field "Write access to read-only attributes", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[apiv3_write_readonly_attributes]"
    end

    expect(rendered_form).to have_field "Enable docs page", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[apiv3_docs_enabled]"
    end

    expect(rendered_form).to have_field "Enable CORS", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[apiv3_cors_enabled]"
    end

    expect(rendered_form).to have_field "API V3 Cross-Origin Resource Sharing (CORS) allowed origins",
                                        type: :textarea,
                                        disabled: true do |field|
      expect(field["name"]).to eq "settings[apiv3_cors_origins]"
    end
  end
end
