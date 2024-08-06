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

RSpec.describe API::V3::Projects::ProjectEagerLoadingWrapper do
  shared_let(:projects) { create_list(:project, 3) }

  before do
    allow(User).to receive(:current).and_return build_stubbed(:admin)
  end

  describe ".wrap" do
    subject(:loaded_projects) { described_class.wrap(projects) }

    it "returns wrapped projects with relations eager loaded" do
      expect(loaded_projects.size).to eq(projects.size)
      association_names = %i[@available_custom_fields @ancestors_from_root]
      loaded_projects.each do |loaded_project|
        association_names.each do |association|
          expect(loaded_project.__getobj__.instance_variables).to include(association)
        end
      end
    end

    context "with available custom fields" do
      let!(:text_project_custom_field) do
        create :text_project_custom_field, projects: [projects.second, projects.third]
      end

      let!(:string_project_custom_field) do
        create :string_project_custom_field, projects: [projects.third]
      end

      it "returns available custom fields for each project separately" do
        expect(loaded_projects.first.available_custom_fields).to eq([])
        expect(loaded_projects.second.available_custom_fields).to eq([text_project_custom_field])
        expect(loaded_projects.third.available_custom_fields)
          .to eq([text_project_custom_field, string_project_custom_field])
      end
    end
  end
end
