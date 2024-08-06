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

RSpec.describe API::V3::Capabilities::CapabilitySqlRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:scope) do
    Capability
      .where(principal_id: principal.id,
             context_id: context&.id)
      .order(:action)
      .limit(1)
  end
  let(:principal) do
    create(:user,
           member_with_permissions: { project => %i[view_members] })
  end
  let(:project) do
    create(:project)
  end
  let(:context) do
    project
  end

  current_user do
    create(:user,
           member_with_permissions: { project => [] })
  end

  subject(:json) do
    API::V3::Utilities::SqlRepresenterWalker
      .new(
        scope,
        current_user:,
        url_query: { select: { "id" => {}, "_type" => {}, "self" => {}, "action" => {}, "context" => {}, "principal" => {} } }
      )
      .walk(described_class)
      .to_json
  end

  context "with a project and user" do
    it "renders as expected" do
      expect(json)
        .to be_json_eql({
          id: "activities/read/p#{context.id}-#{principal.id}",
          _type: "Capability",
          _links: {
            context: {
              href: api_v3_paths.project(project.id),
              title: project.name
            },
            principal: {
              href: api_v3_paths.user(principal.id),
              title: principal.name
            },
            action: {
              href: api_v3_paths.action("activities/read")
            },
            self: {
              href: api_v3_paths.capability("activities/read/p#{context.id}-#{principal.id}")
            }
          }
        }.to_json)
    end
  end

  context "with a project and group" do
    let(:principal) do
      create(:group,
             member_with_permissions: { project => %i[view_members] })
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql({
          id: "memberships/read/p#{context.id}-#{principal.id}",
          _type: "Capability",
          _links: {
            context: {
              href: api_v3_paths.project(project.id),
              title: project.name
            },
            principal: {
              href: api_v3_paths.group(principal.id),
              title: principal.name
            },
            action: {
              href: api_v3_paths.action("activities/read")
            },
            self: {
              href: api_v3_paths.capability("activities/read/p#{context.id}-#{principal.id}")
            }
          }
        }.to_json)
    end
  end

  context "with a global permission" do
    let(:principal) do
      create(:user,
             global_permissions: %i[create_user],
             member_with_permissions: { project => [] })
    end
    let(:context) { nil }

    it "renders as expected" do
      expect(json)
        .to be_json_eql({
          id: "users/create/g-#{principal.id}",
          _type: "Capability",
          _links: {
            context: {
              href: api_v3_paths.capabilities_contexts_global,
              title: "Global"
            },
            principal: {
              href: api_v3_paths.user(principal.id),
              title: principal.name
            },
            action: {
              href: api_v3_paths.action("users/create")
            },
            self: {
              href: api_v3_paths.capability("users/create/g-#{principal.id}")
            }
          }
        }.to_json)
    end
  end
end
