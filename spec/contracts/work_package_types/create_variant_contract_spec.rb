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

module WorkPackageTypes
  RSpec.describe CreateVariantContract do
    shared_let(:bug) { create(:type, name: "Bug") }
    shared_let(:project) { create(:project) }

    let(:user) { create(:user, member_with_permissions: { project => %i[manage_project_variants] }) }
    let(:owner) { project }
    let(:variant) { bug.variants.new(variant_name: "Internal review", project: owner) }

    subject(:contract) { described_class.new(variant, user, options: {}) }

    def base_errors
      contract.validate
      contract.errors.symbols_for(:base)
    end

    context "when the type allows project-specific variants" do
      it "is valid" do
        expect(base_errors).to be_empty
      end
    end

    context "when the type does not allow project-specific variants" do
      before { bug.update!(allow_project_variants: false) }

      it "refuses it" do
        expect(base_errors).to include(:project_variants_not_allowed)
      end

      context "and the user is an administrator" do
        let(:user) { create(:admin) }

        it "refuses it as well" do
          expect(base_errors).to include(:project_variants_not_allowed)
        end
      end

      context "and the variant is a global one" do
        let(:user) { create(:admin) }
        let(:owner) { nil }

        it "allows it: the setting governs only the variants a project owns" do
          expect(base_errors).to be_empty
        end
      end
    end
  end
end
