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

require "rails_helper"

RSpec.describe Users::Profile::SectionAttributes do
  shared_let(:section) { create(:user_custom_field_section, name: "Profile info") }
  shared_let(:custom_field) do
    create(:user_custom_field, :string, name: "Job title", user_custom_field_section: section)
  end
  shared_let(:user) do
    create(:user,
           firstname: "Sarah",
           lastname: "Chen",
           login: "schen",
           mail: "s.chen@example.com",
           language: "en",
           custom_values: [build(:custom_value, custom_field:, value: "Developer")])
  end

  # attribute_order interleaves built-ins and the custom field
  before do
    section.update_column(:attribute_order, ["firstname", custom_field.column_name, "mail", "language"])
  end

  subject(:attributes) { described_class.for(section:, user:, current_user:) }

  def labels = attributes.map(&:label)
  def values = attributes.map(&:value)

  context "when current_user is the profile owner (self)" do
    let(:current_user) { user }

    it "returns built-ins and custom fields in attribute_order" do
      expect(labels).to eq([
                             User.human_attribute_name("firstname"),
                             "Job title",
                             User.human_attribute_name("mail"),
                             User.human_attribute_name("language")
                           ])
      expect(values).to eq(["Sarah", "Developer", "s.chen@example.com", "English"])
    end
  end

  context "when current_user can manage users" do
    let(:current_user) { create(:user) }

    before { mock_permissions_for(current_user) { |mock| mock.allow_globally(:manage_user) } }

    it "shows the manage-gated built-ins and the email" do
      expect(labels).to include(User.human_attribute_name("firstname"),
                                User.human_attribute_name("mail"),
                                User.human_attribute_name("language"))
    end
  end

  context "when current_user only has view_user_email" do
    let(:current_user) { create(:user) }

    before { mock_permissions_for(current_user) { |mock| mock.allow_globally(:view_user_email) } }

    it "shows the email but not the manage-gated built-ins" do
      expect(labels).to include(User.human_attribute_name("mail"), "Job title")
      expect(labels).not_to include(User.human_attribute_name("firstname"),
                                    User.human_attribute_name("language"))
    end
  end

  context "when current_user is a regular viewer" do
    let(:current_user) { create(:user) }

    before { mock_permissions_for(current_user) {} } # rubocop:disable Lint/EmptyBlock -- viewer with no global permissions

    it "shows no gated built-ins (only the visible custom field)" do
      expect(labels).to eq(["Job title"])
    end
  end

  context "with a blank built-in value" do
    let(:current_user) { user }

    before { user.update_column(:language, "") }

    it "skips the blank attribute" do
      expect(labels).not_to include(User.human_attribute_name("language"))
    end
  end

  context "with a multi-value custom field" do
    shared_let(:multi_cf) do
      create(:user_custom_field, :multi_list, name: "Skills", user_custom_field_section: section)
    end
    let(:current_user) { user }
    let(:user) do
      create(:user, custom_values: multi_cf.possible_values.first(2).map do |v|
        build(:custom_value, custom_field: multi_cf, value: v)
      end)
    end

    before { section.update_column(:attribute_order, [multi_cf.column_name]) }

    it "exposes the values as an array and flags multi_value?" do
      attribute = attributes.first
      expect(attribute.value).to eq(%w[A B])
      expect(attribute).to be_multi_value
    end
  end
end
