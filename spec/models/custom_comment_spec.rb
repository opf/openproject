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

RSpec.describe CustomComment do
  describe "validations" do
    let(:custom_field) { create(:project_custom_field) }
    let(:customized) { create(:project) }

    it { is_expected.to validate_presence_of(:customized) }
    it { is_expected.to validate_presence_of(:custom_field) }

    it "validates uniqueness of custom_field scoped to customized" do
      create(:custom_comment, custom_field:, customized:)
      duplicate = build(:custom_comment, custom_field:, customized:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors).to be_of_kind(:custom_field, :taken)
    end
  end

  describe "comment normalization" do
    let(:comment) { create(:custom_comment, text: "Line 1\r\nLine 2\rLine 3\nLine 4") }

    it "normalizes newlines on save to not need to deal with it in journal" do
      expect(comment.text).to eq("Line 1\nLine 2\nLine 3\nLine 4")
      expect(comment.reload.text).to eq("Line 1\nLine 2\nLine 3\nLine 4")
    end
  end
end
