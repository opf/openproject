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

RSpec.describe Projects::UpdateService, "integration", type: :model do
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) do
    create(:project_role,
           permissions:)
  end
  let(:permissions) do
    %i(edit_project view_project_attributes edit_project_attributes)
  end

  let!(:project) do
    create(:project,
           custom_field.attribute_name => 1,
           status_code:,
           status_explanation:)
  end
  let(:instance) { described_class.new(user:, model: project) }
  let(:custom_field) { create(:integer_project_custom_field) }
  let(:status_code) { nil }
  let(:status_explanation) { nil }
  let(:attributes) { {} }
  let(:service_result) do
    instance
      .call(attributes)
  end

  describe "#call" do
    context "if only a custom field is updated" do
      let(:attributes) do
        { custom_field.attribute_name => 8 }
      end

      it "touches the project after saving" do
        former_updated_at = Project.pluck(:updated_at).first

        service_result

        later_updated_at = Project.pluck(:updated_at).first

        expect(former_updated_at)
          .not_to eql later_updated_at
      end
    end

    context "if a new custom field gets a value assigned" do
      let(:custom_field2) { create(:text_project_custom_field) }

      let(:attributes) do
        { custom_field2.attribute_name => "some text" }
      end

      it "touches the project after saving" do
        former_updated_at = Project.pluck(:updated_at).first

        service_result

        later_updated_at = Project.pluck(:updated_at).first

        expect(former_updated_at)
          .not_to eql later_updated_at
      end
    end

    context "when saving the status as well as the parent" do
      let(:parent_project) { create(:project, members: { user => parent_role }) }
      let(:parent_role) { create(:project_role, permissions: %i(add_subprojects)) }
      let(:status_code) { "on_track" }
      let(:status_explanation) { "some explanation" }
      let(:attributes) do
        {
          parent_id: parent_project.id,
          status_code: "off_track"
        }
      end

      it "updates both the status as well as the parent" do
        service_result

        expect(project.parent)
          .to eql parent_project

        expect(project)
          .to be_off_track
      end
    end
  end

  context "with the seeded demo project" do
    let(:demo_project) { create(:project, name: "Demo project", identifier: "demo-project", public: true) }
    let(:instance) { described_class.new(user:, model: demo_project) }
    let(:attributes) do
      { public: false }
    end

    it "saves in a Setting that the demo project was made private (regression #52826)" do
      # Make the demo project private
      service_result
      expect(demo_project.public).to be(false)

      # Demo project is not available for the onboarding tour any more
      expect(Setting.demo_projects_available).to be(false)
    end
  end
end
