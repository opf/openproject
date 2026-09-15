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

RSpec.describe Queries::Members::Filters::RoleFilter do
  shared_let(:role1) { create(:project_role, name: "Bravo") }
  shared_let(:role2) { create(:project_role, name: "Alpha") }

  it_behaves_like "basic query filter" do
    let(:class_key) { :role_id }
    let(:type) { :list_optional }
    let(:name) { Member.human_attribute_name(:role) }

    describe "#allowed_values" do
      it "is a list of the possible values, ordered by name" do
        expect(instance.allowed_values).to eq([[role2.name, role2.id], [role1.name, role1.id]])
      end

      it "lists a role holding several permissions only once" do
        expect(role1.permissions.size).to be > 1

        expect(instance.allowed_values.count { |(_, id)| id == role1.id }).to eq(1)
      end
    end
  end

  it_behaves_like "list_optional query filter" do
    let(:attribute) { :role_id }
    let(:model) { Member }
    let(:joins) { :member_roles }
    let(:valid_values) { [role1.id.to_s] }
  end
end
