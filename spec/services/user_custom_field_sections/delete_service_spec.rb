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

RSpec.describe UserCustomFieldSections::DeleteService do
  let(:admin) { build_stubbed(:admin) }
  let(:user) { build_stubbed(:user) }
  let(:section) { create(:user_custom_field_section) }

  context "when called by an admin on an empty section" do
    subject(:call) { described_class.new(user: admin, model: section).call }

    it "deletes the section" do
      expect(call).to be_success
      expect(UserCustomFieldSection.exists?(section.id)).to be(false)
    end
  end

  context "when called by a non-admin" do
    subject(:call) { described_class.new(user: user, model: section).call }

    it "fails authorization" do
      expect(call).not_to be_success
      expect(UserCustomFieldSection.exists?(section.id)).to be(true)
    end
  end

  context "when the section has custom fields" do
    before { create(:user_custom_field, user_custom_field_section: section) }

    subject(:call) { described_class.new(user: admin, model: section).call }

    it "fails with an in_use error" do
      expect(call).not_to be_success
      expect(call.result.errors).to be_of_kind(:base, :in_use)
    end

    it "does not delete the section" do
      call
      expect(UserCustomFieldSection.exists?(section.id)).to be(true)
    end
  end
end
