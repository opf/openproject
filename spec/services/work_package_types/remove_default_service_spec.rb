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

RSpec.describe WorkPackageTypes::RemoveDefaultService do
  let(:user) { create(:admin) }

  subject(:service) { described_class.new(variant:, user:) }

  describe "#call" do
    context "when the variant carries the flag" do
      let(:type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let(:variant) { type.default_variant }

      it "clears the flag" do
        expect(service.call).to be_success
        expect(variant.reload).not_to be_enabled_in_new_projects
      end
    end

    context "when the variant does not carry the flag" do
      let(:variant) { create(:type).default_variant }

      it "leaves it unmarked" do
        expect(service.call).to be_success
        expect(variant.reload).not_to be_enabled_in_new_projects
      end
    end

    context "with another type carrying the flag" do
      let!(:other_type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let(:type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let(:variant) { type.default_variant }

      it "only clears the flag on the given variant" do
        expect(service.call).to be_success
        expect(variant.reload).not_to be_enabled_in_new_projects
        expect(other_type.default_variant.reload).to be_enabled_in_new_projects
      end
    end

    context "when the variant is invalid" do
      let(:type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let(:variant) { type.default_variant }

      before { allow(variant).to receive(:valid?).and_return(false) }

      it "fails and leaves the flag untouched" do
        expect(service.call).to be_failure
        expect(variant.reload).to be_enabled_in_new_projects
      end
    end
  end
end
