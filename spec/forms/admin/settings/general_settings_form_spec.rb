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

RSpec.describe Admin::Settings::GeneralSettingsForm, type: :forms do
  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", model: false, scope: :settings } }

  subject(:rendered_form) do
    vc_render_form
    page
  end

  it "renders", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
    expect(rendered_form).to have_field "Application title", type: :text do |field|
      expect(field["name"]).to eq "settings[app_title]"
    end

    expect(rendered_form).to have_field "Objects per page options", type: :text do |field|
      expect(field["name"]).to eq "settings[per_page_options]"
    end

    expect(rendered_form).to have_field "Days displayed on project activity", type: :number,
                                                                              accessible_description: "days" do |field|
      expect(field["name"]).to eq "settings[activity_days_default]"
    end

    expect(rendered_form).to have_field "Host name", type: :text do |field|
      expect(field["name"]).to eq "settings[host_name]"
    end

    expect(rendered_form).to have_field "Cache formatted text", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[cache_formatted_text]"
    end

    expect(rendered_form).to have_field "Allowed link protocols", type: :textarea do |field|
      expect(field["name"]).to eq "settings[allowed_link_protocols]"
    end

    expect(rendered_form).to have_field "Enable Feeds", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[feeds_enabled]"
    end

    expect(rendered_form).to have_field "Feed content limit", type: :number do |field|
      expect(field["name"]).to eq "settings[feeds_limit]"
    end

    expect(rendered_form).to have_field "Max size of text files displayed inline", type: :number,
                                                                                   accessible_description: "kB" do |field|
      expect(field["name"]).to eq "settings[file_max_size_displayed]"
    end

    expect(rendered_form).to have_field "Max number of diff lines displayed", type: :number do |field|
      expect(field["name"]).to eq "settings[diff_max_lines_displayed]"
    end
  end
end
