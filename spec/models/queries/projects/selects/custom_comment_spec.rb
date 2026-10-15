# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Queries::Projects::Selects::CustomComment do
  shared_let(:project) { create(:project) }
  shared_let(:commentable) { create(:string_project_custom_field, :has_comment, projects: [project]) }
  shared_let(:admin_commentable) do
    create(:string_project_custom_field, :admin_only, :has_comment, projects: [project])
  end
  shared_let(:without_comments) { create(:string_project_custom_field, projects: [project]) }

  subject(:available_attributes) { described_class.all_available.map(&:attribute) }

  before do
    RequestStore.clear!
  end

  context "for an admin" do
    current_user { create(:admin) }

    it "includes commentable regular and admin-only fields" do
      expect(available_attributes)
        .to contain_exactly(:"cfc_#{commentable.id}", :"cfc_#{admin_commentable.id}")
    end
  end

  context "for a non-admin" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project_attributes] }) }

    it "excludes fields without comments and admin-only fields" do
      expect(available_attributes).to contain_exactly(:"cfc_#{commentable.id}")
    end
  end
end
