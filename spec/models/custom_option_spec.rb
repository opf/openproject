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

RSpec.describe CustomOption do
  let(:custom_field) do
    cf = build(:wp_custom_field, field_format: "list")
    cf.custom_options.build(value: "some value")

    cf
  end

  let(:custom_option) { custom_field.custom_options.first }

  before do
    custom_field.save!
  end

  describe "saving" do
    it "updates the custom_field's timestamp" do
      timestamp_before = custom_field.updated_at
      sleep 1
      custom_option.touch
      expect(custom_field.reload.updated_at).not_to eql(timestamp_before)
    end
  end

  describe ".destroy" do
    context "with more than one option for the cf" do
      before do
        create(:custom_option, custom_field:)
      end

      it "removes the option" do
        custom_option.destroy

        expect(CustomOption.where(id: custom_option.id).count)
          .to be 0
      end

      it "updates the custom_field's timestamp" do
        timestamp_before = custom_field.updated_at
        sleep 1
        custom_option.destroy
        expect(custom_field.reload.updated_at).not_to eql(timestamp_before)
      end
    end

    context "with only one option for the cf" do
      before do
        custom_option.destroy
      end

      it "reports an error" do
        expect(custom_option.errors[:base])
          .to contain_exactly(I18n.t(:"activerecord.errors.models.custom_field.at_least_one_custom_option"))
      end

      it "does not remove the custom option" do
        expect(CustomOption.where(id: custom_option.id).count)
          .to be 1
      end
    end
  end
end
