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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require Rails.root.join("db/migrate/20261110082955_add_labels_to_all_forms.rb")

RSpec.describe AddLabelsToAllForms, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let(:form_configuration) { create(:form_configuration) }
  let!(:details_group) { create(:form_configuration_group, :default, form_configuration:) }
  let!(:other_group) { create(:form_configuration_group, form_configuration:) }

  def member_keys(group) = group.reload.members.map(&:key)

  before do
    create(:form_configuration_attribute, form_configuration:, group: details_group, position: 1,
                                          attribute_key: "priority")
    create(:form_configuration_attribute, form_configuration:, group: details_group, position: 2,
                                          attribute_key: "category")
  end

  context "with a form configuration that has no labels field" do
    it "adds labels at the end of the details group" do
      migrate

      expect(member_keys(details_group)).to eq %w[priority category labels]
      expect(member_keys(other_group)).to be_empty
    end
  end

  context "with a form configuration that has labels in a group other than details" do
    before do
      create(:form_configuration_attribute, form_configuration:, group: other_group, position: 1,
                                            attribute_key: "labels")
    end

    it "leaves labels where it is" do
      migrate

      expect(member_keys(details_group)).to eq %w[priority category]
      expect(member_keys(other_group)).to eq %w[labels]
    end
  end

  context "with a form configuration that has labels in the details group" do
    before do
      create(:form_configuration_attribute, form_configuration:, group: details_group, position: 3,
                                            attribute_key: "labels")
    end

    it "does not add labels again" do
      migrate

      expect(member_keys(details_group)).to eq %w[priority category labels]
    end
  end

  context "with several form configurations" do
    let(:default_form_configuration) { create(:form_configuration, is_default: true) }
    let!(:default_details_group) do
      create(:form_configuration_group, :default, form_configuration: default_form_configuration)
    end

    before do
      create(:form_configuration_attribute, form_configuration: default_form_configuration,
                                            group: default_details_group, position: 1, attribute_key: "priority")
      create(:form_configuration_attribute, form_configuration:, group: details_group, position: 3,
                                            attribute_key: "labels")
    end

    it "adds labels only to the forms that lack it" do
      migrate

      expect(member_keys(default_details_group)).to eq %w[priority labels]
      expect(member_keys(details_group)).to eq %w[priority category labels]
    end
  end

  context "with a form configuration that has an empty details group" do
    let(:empty_form_configuration) { create(:form_configuration) }
    let!(:empty_details_group) do
      create(:form_configuration_group, :default, form_configuration: empty_form_configuration)
    end

    it "adds labels as the first member of the details group" do
      migrate

      expect(empty_details_group.reload.members.map { [it.key, it.position] }).to eq [["labels", 1]]
    end
  end

  context "with a form configuration that has no details group" do
    let(:custom_form_configuration) { create(:form_configuration) }
    let!(:custom_group) { create(:form_configuration_group, form_configuration: custom_form_configuration) }

    it "leaves the form untouched" do
      migrate

      expect(member_keys(custom_group)).to be_empty
      expect(FormConfigurationAttribute.where(form_configuration: custom_form_configuration)).to be_empty
    end
  end
end
