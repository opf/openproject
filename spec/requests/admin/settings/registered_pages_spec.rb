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

require "spec_helper"

RSpec.describe "Registered settings pages",
               :settings_reset,
               type: :rails_request,
               with_ee: %i[sso_auth_providers],
               with_flag: { llm_connection: true, ai_text_transform_actions: true } do
  shared_let(:admin) { create(:admin) }

  before { login_as(admin) }

  def rendered_setting_names
    response
      .parsed_body
      .css("[name^='settings[']")
      .map { it["name"][/\Asettings\[([^\]]+)\]/, 1].to_sym }
      .select { Settings::Definition.exists?(it) }
      .uniq
  end

  def marked_setting_names
    response.parsed_body.css("[data-setting-name]").map { it["data-setting-name"].to_sym }.uniq
  end

  shared_examples "registered settings pages" do
    Settings::Pages.all.each do |settings_page|
      it "lists exactly the settings rendered on the #{settings_page.key} page", :aggregate_failures do
        get url_for(**settings_page.url, only_path: true)

        entries = settings_page.sections.flat_map(&:visible_entries)
        form_fields, other = entries.partition(&:form_field?)

        expect(rendered_setting_names).to match_array(form_fields.map(&:name))
        expect(other.map(&:name) - marked_setting_names).to be_empty
      end
    end
  end

  it_behaves_like "registered settings pages"

  context "with optional states enabled",
          with_settings: {
            work_package_multiple_versions: false,
            real_time_text_collaboration_enabled: true,
            collaborative_editing_hocuspocus_url: "wss://hocuspocus.example.com",
            collaborative_editing_hocuspocus_secret: "secret"
          } do
    it_behaves_like "registered settings pages"
  end
end
