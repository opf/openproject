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

RSpec.describe Queries::Roles::Filters::AllowsBecomingAssigneeFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :allows_becoming_assignee }
    let(:type) { :list }
    let(:model) { Role }
  end

  it_behaves_like "boolean query filter", scope: false do
    let(:model) { Role }
    let(:attribute) { :type }
    let(:permission_name) { "work_package_assigned" }
  end

  describe "#apply_to" do
    shared_let(:assignable_role) do
      create(:project_role,
             name: "assignable_role",
             permissions: %i[work_package_assigned],
             add_public_permissions: false)
    end
    shared_let(:unassignable_role) do
      create(:project_role,
             name: "unassignable_role",
             permissions: %i[wrong],
             add_public_permissions: false)
    end

    let(:instance) do
      described_class.create!.tap do |filter|
        filter.values = values
        filter.operator = operator
      end
    end

    subject { instance.apply_to(Role).map(&:name) }

    context 'with a "=" operator' do
      let(:operator) { "=" }

      context 'with a "true" value' do
        let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

        it { is_expected.to contain_exactly(assignable_role.name) }
      end

      context 'with a "false" value' do
        let(:values) { [OpenProject::Database::DB_VALUE_FALSE] }

        it { is_expected.to contain_exactly(unassignable_role.name) }
      end
    end

    context 'with a "!" operator' do
      let(:operator) { "!" }

      context 'with a "true" value' do
        let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

        it { is_expected.to contain_exactly(unassignable_role.name) }
      end

      context 'with a "false" value' do
        let(:values) { [OpenProject::Database::DB_VALUE_FALSE] }

        it { is_expected.to contain_exactly(assignable_role.name) }
      end
    end
  end
end
