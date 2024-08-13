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

RSpec.describe ProjectsHelper do
  include ApplicationHelper
  include described_class

  let(:project_selects) do
    selects = [
      Queries::Projects::Selects::Default.new(:name),
      Queries::Projects::Selects::Default.new(:hierarchy),
      Queries::Projects::Selects::Default.new(:description),
      Queries::Projects::Selects::Status.new(:project_status)
    ]

    query_instance = instance_double(ProjectQuery, available_selects: selects)

    allow(ProjectQuery)
      .to receive(:new)
            .and_return(query_instance)
  end

  describe "#short_project_description" do
    let(:project) { build_stubbed(:project, description: "#{'Abcd ' * 5}\n" * 11) }

    it "returns shortened description" do
      expect(helper.short_project_description(project))
        .to eql("#{("#{'Abcd ' * 5}\n" * 10)[0..-2]}...")
    end
  end

  describe "#projects_columns_options" do
    before do
      project_selects
    end

    it "returns the columns options" do
      expect(helper.projects_columns_options)
        .to eql([
                  { name: "Description", id: :description },
                  { name: "Name", id: :name },
                  { name: "Status", id: :project_status }
                ])
    end
  end

  describe "#selected_project_columns_options", with_settings: { enabled_projects_columns: %w[name description] } do
    before do
      project_selects
    end

    it "returns the columns options currently persisted in the setting (in that order)" do
      expect(helper.selected_projects_columns_options)
        .to eql([
                  { name: "Name", id: :name },
                  { name: "Description", id: :description }
                ])
    end
  end

  describe "#protected_project_columns_options" do
    before do
      project_selects
    end

    it "returns the columns options currently persisted in the setting (in that order)" do
      expect(helper.protected_projects_columns_options)
        .to eql([
                  { name: "Name", id: :name }
                ])
    end
  end
end
