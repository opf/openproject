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

RSpec.describe OpenProject::Common::InplaceEditFields::VersionSelectListComponent,
               type: :component do
  include ViewComponent::TestHelpers

  let(:user_admin) { create(:admin) }
  let(:project) { create(:project) }
  let(:custom_field) { create(:project_custom_field, :version, projects: [project]) }
  let(:attribute) { custom_field.attribute_name.to_sym }
  let(:version1) { create(:version, name: "v1.0", project:) }
  let(:version2) { create(:version, name: "v2.0", project:) }

  before { allow(User).to receive(:current).and_return(user_admin) }

  def render_component(project_model)
    component_class = described_class
    cf_attribute = attribute
    cf_label = custom_field.name
    render_in_view_context(project_model) do |model|
      primer_form_with(url: "/foo", model:) do |f|
        render_inline_form(f) do |form|
          render component_class.new(form:, model:, attribute: cf_attribute, label: cf_label)
        end
      end
    end
  end

  it "renders an autocompleter for a version custom field" do
    version1
    version2
    render_component(project)

    expect(rendered_content).to have_css("opce-autocompleter")
    # Options are serialised as JSON in the opce-autocompleter's items attribute
    expect(rendered_content).to include("v1.0")
    expect(rendered_content).to include("v2.0")
  end

  it "marks the currently selected version via the model attribute" do
    version1
    create(:custom_value, :skip_validations, customized: project, custom_field:, value: version1.id.to_s)
    render_component(Project.find(project.id))

    # The decorated autocompleter serialises the selected item as a data-model attribute
    expect(page).to have_element "opce-autocompleter" do |autocompleter|
      expect(autocompleter["data-model"]).to be_json_eql(
        %{{"disabled": false, "group_by": "#{project.name}", "name": "#{version1.name}", "selected": true}}
      )
    end
  end
end
