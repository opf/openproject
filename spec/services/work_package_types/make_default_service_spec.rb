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

  subject(:service) { described_class.new(type:, user:) }

  describe "#call" do
    context "when no family member is the default yet" do
      let(:type) { create(:type, is_default: false) }

      it "marks the type as the default" do
        expect(service.call).to be_success
        expect(type.reload).to be_is_default
      end
    end

    context "when the type is already the default" do
      let(:type) { create(:type, is_default: true) }

      it "leaves it as the default" do
        expect(service.call).to be_success
        expect(type.reload).to be_is_default
      end
    end

    context "when the root is the default and a variant is promoted" do
      let(:root) { create(:type, is_default: true) }
      let(:type) { create(:type, parent: root, is_default: false) }

      it "moves the flag from the root to the variant" do
        expect(service.call).to be_success
        expect(type.reload).to be_is_default
        expect(root.reload).not_to be_is_default
      end
    end

    context "when a sibling variant is the default" do
      let(:root) { create(:type, is_default: false) }
      let!(:sibling) { create(:type, parent: root, is_default: true) }
      let(:type) { create(:type, parent: root, is_default: false) }

      it "moves the flag from the sibling to the type" do
        expect(service.call).to be_success
        expect(type.reload).to be_is_default
        expect(sibling.reload).not_to be_is_default
      end
    end

    context "when a variant is the default and the root is promoted" do
      let(:type) { create(:type, is_default: false) }
      let!(:variant) { create(:type, parent: type, is_default: true) }

      it "moves the flag from the variant to the root" do
        expect(service.call).to be_success
        expect(type.reload).to be_is_default
        expect(variant.reload).not_to be_is_default
      end
    end

    context "when several family members carry the flag" do
      let(:root) { create(:type, is_default: true) }
      let!(:sibling) { create(:type, parent: root, is_default: true) }
      let(:type) { create(:type, parent: root, is_default: false) }

      it "leaves the type as the only default in the family" do
        expect(service.call).to be_success
        expect(type.reload).to be_is_default
        expect(root.reload).not_to be_is_default
        expect(sibling.reload).not_to be_is_default
      end
    end

    context "with a default in another family" do
      let(:other_default) { create(:type, is_default: true) }
      let(:type) { create(:type, is_default: false) }

      it "does not touch it" do
        expect(service.call).to be_success
        expect(other_default.reload).to be_is_default
      end
    end

    context "when unmarking the previous default fails" do
      let(:root) { create(:type, is_default: true) }
      let(:type) { create(:type, parent: root, is_default: false) }

      before do
        type
        root.update_column(:name, "")
      end

      it "fails and rolls the whole family back" do
        expect(service.call).to be_failure
        expect(type.reload).not_to be_is_default
        expect(root.reload).to be_is_default
      end
    end
  end
end
