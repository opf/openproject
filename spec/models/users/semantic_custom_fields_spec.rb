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

RSpec.describe Users::SemanticCustomFields do
  subject(:member) { create(:user) }

  before { RequestStore.clear! }

  describe "#job_title" do
    it "is nil when no user custom field is mapped to the job title" do
      expect(member.job_title).to be_nil
    end

    context "with a mapped field" do
      let!(:field) { create(:user_custom_field, :string, name: "Position", semantic_key: :job_title) }

      it "is nil when the user has no value for it" do
        expect(member.job_title).to be_nil
      end

      it "returns the user's value" do
        member.custom_values.create!(custom_field: field, value: "Frontend Developer")

        expect(member.job_title).to eq("Frontend Developer")
      end

      it "ignores the values of other custom fields" do
        other_field = create(:user_custom_field, :string, name: "Nickname")
        member.custom_values.create!(custom_field: other_field, value: "Ada")

        expect(member.job_title).to be_nil
      end

      it "reads preloaded custom values rather than loading them again" do
        member.custom_values.create!(custom_field: field, value: "Frontend Developer")

        preloaded = User.where(id: member.id).includes(custom_values: :custom_field).first

        expect(preloaded.job_title).to eq("Frontend Developer")
        expect(preloaded.custom_values).to be_loaded
      end
    end

    context "with a mapped multi-value field" do
      let!(:field) do
        create(:user_custom_field, :multi_list, name: "Roles", semantic_key: :job_title,
                                                possible_values: %w[Backend Frontend])
      end

      it "joins the values" do
        field.custom_options.each do |option|
          member.custom_values.create!(custom_field: field, value: option.id)
        end

        expect(member.job_title).to eq("Backend, Frontend")
      end
    end
  end
end
