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

RSpec.describe Admin::Settings::RepositoriesSettingsForm, type: :forms do
  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", model: false, scope: :settings } }

  subject(:rendered_form) do
    vc_render_form
    page
  end

  it "renders", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
    expect(rendered_form).to have_field "Autofetch repository changes", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[autofetch_changesets]"
    end

    expect(rendered_form).to have_field "Repository disk size cache", type: :number,
                                                                      accessible_description: "minutes" do |field|
      expect(field["name"]).to eq "settings[repository_storage_cache_minutes]"
    end

    expect(rendered_form).to have_field "Enable repository management web service", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[sys_api_enabled]"
    end

    expect(rendered_form).to have_field "API key", type: :text, disabled: true do |field|
      expect(field["name"]).to eq "settings[sys_api_key]"
    end

    expect(rendered_form).to have_field "settings[enabled_scm][]", type: :hidden, with: "" # auxiliary field

    expect(rendered_form).to have_field "Subversion", type: :checkbox, fieldset: "Enabled SCM" do |field|
      expect(field["name"]).to eq "settings[enabled_scm][]"
      expect(field["value"]).to eq "subversion"
    end
    expect(rendered_form).to have_field "Git", type: :checkbox, fieldset: "Enabled SCM" do |field|
      expect(field["name"]).to eq "settings[enabled_scm][]"
      expect(field["value"]).to eq "git"
    end

    expect(rendered_form).to have_select "Automatic repository vendor type" do |select|
      expect(select["name"]).to eq "settings[repositories_automatic_managed_vendor]"
    end

    expect(rendered_form).to have_field "Repositories encodings", type: :text do |field|
      expect(field["name"]).to eq "settings[repositories_encodings]"
    end

    expect(rendered_form).to have_field "Maximum number of revisions displayed on file log", type: :number do |field|
      expect(field["name"]).to eq "settings[repository_log_display_limit]"
    end

    expect(rendered_form).to have_field "Maximum number of files displayed in the repository browser", type: :number do |field|
      expect(field["name"]).to eq "settings[repository_truncate_at]"
    end
  end
end
