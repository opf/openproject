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

RSpec.describe "Work package type tab page titles",
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }

  before { login_as admin }

  def page_title
    response.parsed_body.at_css("title")&.text
  end

  def tab_paths(args)
    {
      details: edit_type_details_path(**args),
      form_configuration: edit_type_form_configuration_path(**args),
      defaults: edit_type_defaults_path(**args),
      projects: edit_type_projects_path(**args),
      project_attributes: edit_type_project_attributes_path(**args),
      workflow: edit_type_workflow_path(**args),
      pdf_export: edit_type_pdf_export_template_index_path(**args)
    }
  end

  it "names the variant on every tab", :aggregate_failures do
    tab_paths(variant.path_args).each do |tab, path|
      get path

      expect(page_title).to include("Bug: Hardware"), "expected the #{tab} tab title to name the variant"
    end
  end

  it "names the type on the tabs of its base variant", :aggregate_failures do
    tab_paths(type.default_variant.path_args).each do |tab, path|
      get path

      expect(page_title).to include("Bug"), "expected the #{tab} tab title to name the type"
      expect(page_title).not_to include("Bug: "), "expected the #{tab} tab title to omit a variant name"
    end
  end
end
