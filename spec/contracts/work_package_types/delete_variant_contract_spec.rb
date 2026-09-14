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
  RSpec.describe DeleteVariantContract do
    shared_let(:bug) { create(:type, name: "Bug") }

    let(:user) { create(:admin) }
    let(:variant) { create(:type_variant, type: bug, variant_name: "Hardware") }
    let(:target) { nil }

    subject(:contract) { described_class.new(variant, user, options: { target: }) }

    def base_errors
      contract.validate
      contract.errors.symbols_for(:base)
    end

    context "when the user is not an admin" do
      let(:user) { create(:user) }

      it "is unauthorized" do
        expect(base_errors).to include(:error_unauthorized)
      end
    end

    context "when the variant is the default" do
      let(:variant) { bug.default_variant }

      it "refuses it" do
        expect(base_errors).to include(:is_default_variant)
      end
    end

    context "without a target (plain delete)" do
      it "is valid" do
        expect(base_errors).to be_empty
      end
    end

    context "with a target that is a valid migration target" do
      let(:target) { create(:type_variant, type: bug, variant_name: "Firmware") }

      it "is valid" do
        expect(base_errors).to be_empty
      end
    end

    context "with a target that is not a migration target" do
      let(:target) { create(:type_variant, type: create(:type, name: "Task"), variant_name: "Onsite") }

      it "refuses it" do
        expect(base_errors).to include(:migration_target_invalid)
      end
    end
  end
end
