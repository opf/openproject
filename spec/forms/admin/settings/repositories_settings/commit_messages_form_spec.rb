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

RSpec.describe Admin::Settings::RepositoriesSettings::CommitMessagesForm, type: :forms do
  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", model: false, scope: :settings } }

  let!(:time_entry_activities) do
    [
      create(:time_entry_activity, name: "Zähneputzen"),
      create(:time_entry_activity, name: "Bügeln")
    ]
  end
  let!(:statuses) do
    [
      create(:status, name: "In Arbeit"),
      create(:status, name: "Fast fertig"),
      create(:status, name: "Großes Fiasko")
    ]
  end

  subject(:rendered_form) do
    vc_render_form
    page
  end

  it "renders", :aggregate_failures do
    expect(rendered_form).to have_field "Referencing keywords", type: :text do |field|
      expect(field["name"]).to eq "settings[commit_ref_keywords]"
    end

    expect(rendered_form).to have_field "Fixing keywords: Keywords", type: :text do |field|
      expect(field["name"]).to eq "settings[commit_fix_keywords]"
    end

    expect(rendered_form).to have_select "Fixing keywords: Applied status" do |select|
      expect(select["name"]).to eq "settings[commit_fix_status_id]"

      expect(select).to have_selector :option, count: 4
      expect(select).to have_selector :option, "Fast fertig"
      expect(select).to have_selector :option, "Großes Fiasko"
      expect(select).to have_selector :option, "In Arbeit"
    end

    expect(rendered_form).to have_field "Enable time logging", type: :checkbox do |field|
      expect(field["name"]).to eq "settings[commit_logtime_enabled]"
    end

    expect(rendered_form).to have_select "Activity for logged time", disabled: true do |select|
      expect(select["name"]).to eq "settings[commit_logtime_activity_id]"

      expect(select).to have_selector :option, count: 3
      expect(select).to have_selector :option, "Default"
      expect(select).to have_selector :option, "Zähneputzen"
      expect(select).to have_selector :option, "Bügeln"
    end
  end
end
