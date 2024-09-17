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

RSpec.describe Queries::WorkPackages::Filter::RoleFilter do
  let(:role) { build_stubbed(:project_role) }
  let(:all_roles_relation) { [role] }

  def mock_roles_query_chain(return_value)
    allow(Role)
      .to receive(:givable)
            .and_return(return_value)

    return_value
  end

  it_behaves_like "basic query filter" do
    let(:type) { :list_optional }
    let(:class_key) { :assigned_to_role }
    let(:name) { I18n.t("query_fields.assigned_to_role") }

    describe "#available?" do
      context "when any givable role exists" do
        before do
          givable_roles_relation = instance_double(ActiveRecord::Relation)
          allow(givable_roles_relation)
            .to receive(:exists?)
                  .and_return(true)

          mock_roles_query_chain(givable_roles_relation)
        end

        it { expect(instance).to be_available }
      end

      context "when no givable role exists" do
        before do
          givable_roles_relation = instance_double(ActiveRecord::Relation)
          allow(givable_roles_relation)
            .to receive(:exists?)
                  .and_return(false)

          mock_roles_query_chain(givable_roles_relation)
        end

        it { expect(instance).not_to be_available }
      end
    end

    describe "#allowed_values" do
      before do
        mock_roles_query_chain([role])
      end

      it "is an array of role values" do
        expect(instance.allowed_values)
          .to contain_exactly [role.name, role.id.to_s]
      end
    end

    describe "#ar_object_filter?" do
      it "is true" do
        expect(instance)
          .to be_ar_object_filter
      end
    end

    describe "#value_objects" do
      let(:other_role) { build_stubbed(:project_role) }

      before do
        mock_roles_query_chain([role, other_role])
        instance.values = [role.id.to_s, other_role.id.to_s]
      end

      it "returns an array of projects" do
        expect(instance.value_objects)
          .to contain_exactly(role, other_role)
      end
    end
  end
end
