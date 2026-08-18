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

    it "returns the fields configured on types used in projects the user can see" do
      expect(subject).to contain_exactly(type_enabled_and_member_cf,
                                         type_enabled_for_all_cf,
                                         not_a_member_cf,
                                         type_enabled_in_different_project_than_member_cf)
    end
  end

  describe ".visible with a linked form configuration" do
    shared_let(:source_type) { create(:type) }
    shared_let(:linked_type) { create(:type) }
    shared_let(:linked_project) { create(:project, types: [linked_type]) }
    shared_let(:source_cf) do
      create(:integer_wp_custom_field, type_variants: [source_type.default_variant])
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

  end
end
