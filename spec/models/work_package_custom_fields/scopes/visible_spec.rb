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
require_relative "visible_setup"

RSpec.describe WorkPackageCustomFields::Scopes::Visible do
  include_context "given a visible setup"

  describe ".visible" do
    subject { WorkPackageCustomField.visible(user) }

    context "when the user has the select_custom_field_permission in any project" do
      let!(:project_with_select_permissions) { create(:project) }
      let(:user) { create(:user, member_with_permissions: { project_with_select_permissions => [:select_custom_fields] }) }

      it "returns all custom fields" do
        expect(subject).to contain_exactly(type_enabled_and_member_cf,
                                           type_enabled_for_all_cf,
                                           type_non_enabled_in_project_cf,
                                           not_a_member_cf,
                                           type_disabled_for_all_cf,
                                           type_enabled_in_different_project_than_member_cf)
      end
    end

    context "when the user lacks the select_custom_field_permission" do
      it "returns custom fields for types that are enabled in projects the user can see" do
        expect(subject).to contain_exactly(type_enabled_and_member_cf, type_enabled_for_all_cf)
      end
    end
  end

  describe ".visible with a linked form configuration" do
    shared_let(:source_type) { create(:type) }
    shared_let(:linked_type) { create(:type) }
    shared_let(:linked_project) { create(:project, types: [linked_type]) }
    shared_let(:source_cf) do
      create(:integer_wp_custom_field, projects: [linked_project], type_variants: [source_type.default_variant])
    end

    before do
      linked_type.default_variant.update!(form_configuration_source: source_type.default_variant)
    end

    context "for a non-privileged user" do
      shared_let(:member_user) do
        create(:user, member_with_permissions: { linked_project => [] })
      end

      it "surfaces the source variant's fields through the visibility scope" do
        expect(WorkPackageCustomField.visible(member_user)).to include(source_cf)
      end
    end

    context "for a user allowed to select custom fields anywhere" do
      shared_let(:privileged_user) do
        create(:user,
               member_with_permissions: { linked_project => %i[select_custom_fields] })
      end

      it "returns all custom fields (short-circuit unaffected)" do
        expect(WorkPackageCustomField.visible(privileged_user)).to include(source_cf)
      end
    end
  end
end
