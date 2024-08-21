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

# This file can be safely deleted once the feature flag :percent_complete_edition
# is removed, which should happen for OpenProject 15.0 release.
RSpec.describe API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter, "pre 14.4 without percent complete edition",
               with_flag: { percent_complete_edition: false } do
  include API::V3::Utilities::PathHelper

  let(:project) { build_stubbed(:project_with_types) }
  let(:permissions) { [:edit_work_packages] }
  let(:attribute_query) do
    build_stubbed(:query).tap do |query|
      query.filters.clear
      query.add_filter("parent", "=", ["{id}"])
    end
  end
  let(:attribute_groups) do
    [Type::AttributeGroup.new(wp_type, "People", %w(assignee responsible)),
     Type::AttributeGroup.new(wp_type, "Estimates and time", %w(estimated_time spent_time)),
     Type::QueryGroup.new(wp_type, "Children", attribute_query)]
  end
  let(:schema) do
    API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package:).tap do |schema|
      allow(wp_type)
        .to receive(:attribute_groups)
        .and_return(attribute_groups)
      allow(schema)
        .to receive(:assignable_values)
        .and_call_original
      allow(schema)
        .to receive(:assignable_values)
        .with(:version, current_user)
        .and_return([])
    end
  end
  let(:self_link) { "/a/self/link" }
  let(:base_schema_link) { nil }
  let(:hide_self_link) { false }
  let(:embedded) { true }
  let(:representer) do
    described_class.create(schema,
                           self_link:,
                           form_embedded: embedded,
                           base_schema_link:,
                           current_user:)
  end
  let(:available_custom_fields) { [] }
  let(:wp_type) { project.types.first }
  let(:custom_field) { build_stubbed(:custom_field) }
  let(:work_package) do
    build_stubbed(:work_package, project:, type: wp_type) do |wp|
      allow(wp)
        .to receive(:available_custom_fields)
        .and_return(available_custom_fields)
    end
  end
  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project *permissions, project: schema.project
    end

    login_as(current_user)
    allow(schema.project)
      .to receive(:module_enabled?)
      .and_return(true)

    allow(schema).to receive(:writable?).and_call_original
  end

  context "for generation" do
    subject(:generated) { representer.to_json }

    describe "percentageDone" do
      it_behaves_like "has basic schema properties" do
        let(:path) { "percentageDone" }
        let(:type) { "Integer" }
        let(:name) { I18n.t("activerecord.attributes.work_package.done_ratio") }
        let(:required) { false }
        let(:writable) { false }
      end
    end
  end
end
