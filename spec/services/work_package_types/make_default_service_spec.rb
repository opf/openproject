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

RSpec.describe WorkPackageTypes::MakeDefaultService do
  let(:user) { create(:admin) }
  let(:type) { create(:type) }

  subject(:service) { described_class.new(variant:, user:) }

  describe "#call" do
    context "when no variant of the type carries the flag" do
      let(:variant) { type.default_variant }

      it "marks the variant as the one new projects start with" do
        expect(service.call).to be_success
        expect(variant.reload).to be_enabled_in_new_projects
      end
    end

    context "when the variant already carries the flag" do
      let(:type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let(:variant) { type.default_variant }

      it "leaves it carrying the flag" do
        expect(service.call).to be_success
        expect(variant.reload).to be_enabled_in_new_projects
      end
    end

    context "when a sibling variant of the same type carries the flag" do
      let(:type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let!(:sibling) { type.default_variant }
      let(:variant) { create(:type_variant, type:) }

      it "moves the flag off the sibling, so only one remains" do
        expect(service.call).to be_success
        expect(variant.reload).to be_enabled_in_new_projects
        expect(sibling.reload).not_to be_enabled_in_new_projects
      end
    end

    context "when another type carries the flag" do
      let!(:other_type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let(:variant) { type.default_variant }

      it "does not touch it: the flag is unique per type, not across them" do
        expect(service.call).to be_success
        expect(variant.reload).to be_enabled_in_new_projects
        expect(other_type.default_variant.reload).to be_enabled_in_new_projects
      end
    end

    context "when marking the variant fails" do
      let(:type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let!(:sibling) { type.default_variant }
      let(:variant) { create(:type_variant, type:) }

      before { allow(variant).to receive(:valid?).and_return(false) }

      it "fails and rolls the sibling's demotion back" do
        expect(service.call).to be_failure
        expect(variant.reload).not_to be_enabled_in_new_projects
        expect(sibling.reload).to be_enabled_in_new_projects
      end
    end
  end
end
