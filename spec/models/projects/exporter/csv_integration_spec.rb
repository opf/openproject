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
require_relative "exportable_project_context"

RSpec.describe Projects::Exports::CSV, "integration" do
  include_context "with a project with an arrangement of custom fields"
  include_context "with an instance of the described exporter"

  let(:parsed) do
    CSV.parse(output)
  end

  let(:header) { parsed.first }

  let(:rows) { parsed.drop(1) }

  it "performs a successful export" do
    expect(parsed.size).to eq(2)
    expect(parsed.last).to eq [project.id.to_s, project.identifier,
                               project.name, project.description, "Off track", "false"]
  end

  context "with status_explanation enabled" do
    let(:query_columns) { %w[name description project_status status_explanation public] }

    it "performs a successful export" do
      expect(parsed.size).to eq(2)
      expect(parsed.last).to eq [project.id.to_s, project.identifier,
                                 project.name, project.description,
                                 "Off track", "some explanation", "false"]
    end
  end

  describe "custom field columns selected" do
    let(:query_columns) do
      %w[name description project_status public] + global_project_custom_fields.map(&:column_name)
    end

    before do
      project # re-evaluate project to ensure it is created within the desired user context
      parsed
    end

    context "without view_project_attributes permission" do
      let(:permissions) { %i(view_projects) }

      it "does not render project custom fields in the header" do
        expect(parsed.size).to eq 2

        expect(header).to eq ["id", "Identifier", "Name", "Description", "Status", "Public"]
      end

      it "does not render the custom field values in the rows if enabled for a project" do
        expect(rows.first)
          .to eq [project.id.to_s, project.identifier, project.name,
                  project.description, "Off track", "false"]
      end
    end

    context "with view_project_attributes permission" do
      it "renders available project custom fields in the header if enabled in any project" do
        expect(parsed.size).to eq 2

        cf_names = global_project_custom_fields.map(&:name)

        expect(cf_names).not_to include(not_used_string_cf.name)
        expect(cf_names).not_to include(hidden_cf.name)

        expect(header).to eq ["id", "Identifier", "Name", "Description", "Status", "Public", *cf_names]
      end

      it "renders the custom field values in the rows if enabled for a project" do
        custom_values = global_project_custom_fields.map do |cf|
          case cf
          when bool_cf
            "true"
          when text_cf
            project.typed_custom_value_for(cf)
          when not_used_string_cf
            ""
          else
            project.formatted_custom_value_for(cf)
          end
        end
        expect(rows.first)
          .to eq [project.id.to_s, project.identifier, project.name,
                  project.description, "Off track", "false", *custom_values]
      end
    end

    context "with admin permission" do
      let(:current_user) { create(:admin) }

      it "renders all globally available project custom fields including hidden ones in the header" do
        expect(parsed.size).to eq 3

        cf_names = global_project_custom_fields.map(&:name)

        expect(cf_names).to include(not_used_string_cf.name)
        expect(cf_names).to include(hidden_cf.name)

        expect(header).to eq ["id", "Identifier", "Name", "Description", "Status", "Public", *cf_names]
      end

      it "renders the custom field values in the rows if enabled for a project" do
        custom_values = global_project_custom_fields.map do |cf|
          case cf
          when bool_cf
            "true"
          when hidden_cf
            "hidden"
          when not_used_string_cf
            ""
          when text_cf
            project.typed_custom_value_for(cf)
          else
            project.formatted_custom_value_for(cf)
          end
        end
        expect(rows.first)
          .to eq [project.id.to_s, project.identifier, project.name,
                  project.description, "Off track", "false", *custom_values]
      end
    end
  end

  context "with no project visible" do
    let(:current_user) { User.anonymous }

    it "does not include the project" do
      expect(output).not_to include project.identifier
      expect(parsed.size).to eq(1)
    end
  end
end
