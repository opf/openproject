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

  subject(:service) { described_class.new(type:, user:) }

  describe "#call" do
    context "when the type is the default" do
      let(:type) { create(:type, is_default: true) }

      it "clears the flag" do
        expect(service.call).to be_success
        expect(type.reload).not_to be_is_default
      end
    end

    context "when the type is not the default" do
      let(:type) { create(:type, is_default: false) }

      it "leaves it unmarked" do
        expect(service.call).to be_success
        expect(type.reload).not_to be_is_default
      end
    end

    context "with a default on another type" do
      let(:other) { create(:type, is_default: true) }
      let(:type) { create(:type, is_default: true) }

      it "only clears the flag on the given type" do
        expect(service.call).to be_success
        expect(type.reload).not_to be_is_default
        expect(other.reload).to be_is_default
      end
    end

    context "when the type is invalid" do
      let(:type) { create(:type, is_default: true) }

      before { type.update_column(:name, "") }

      it "fails and leaves the flag untouched" do
        expect(service.call).to be_failure
        expect(type.reload).to be_is_default
      end
    end
  end
end
