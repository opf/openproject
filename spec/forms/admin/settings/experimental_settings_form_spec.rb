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

RSpec.describe Admin::Settings::ExperimentalSettingsForm, :settings_reset, type: :forms do
  include_context "with clean feature decisions"
  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", model: false, scope: :settings } }

  subject(:rendered_form) do
    vc_render_form
    page
  end

  context "without feature flags" do
    it "renders" do
      expect(rendered_form).to have_no_field type: :checkbox, fieldset: "Feature flags"
    end
  end

  context "with feature flags" do
    before do
      OpenProject::FeatureDecisions.add :an_example
      OpenProject::FeatureDecisions.add :another_example
    end

    it "renders", :aggregate_failures do
      expect(rendered_form).to have_field count: 2, type: :checkbox, fieldset: "Feature flags"
      expect(rendered_form).to have_field "An example", type: :checkbox, fieldset: "Feature flags"
      expect(rendered_form).to have_field "Another example", type: :checkbox, fieldset: "Feature flags"
    end
  end

  context "with a feature flag that has allow_enabling disabled" do
    before do
      OpenProject::FeatureDecisions.add :an_example, allow_enabling: false
      OpenProject::FeatureDecisions.add :another_example
    end

    it "does not render the disabled flag with a false default", :aggregate_failures do
      expect(rendered_form).to have_field count: 1, type: :checkbox, fieldset: "Feature flags"
      expect(rendered_form).to have_no_field "An example", type: :checkbox, fieldset: "Feature flags"
      expect(rendered_form).to have_field "Another example", type: :checkbox, fieldset: "Feature flags"
    end
  end
end
