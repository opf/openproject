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

RSpec.describe WorkPackageTypes::Patterns::TokenPropertyMapper do
  shared_let(:responsible) { create(:user, firstname: "Responsible") }
  shared_let(:assignee) { create(:user, firstname: "Assignee") }
  shared_let(:version) { create(:version) }
  shared_let(:parent_assignee) { create(:user, firstname: "Parent", lastname: "Assignee") }

  shared_let(:category) { create(:category) }

  shared_let(:project) { create(:project, parent: create(:project), status_code: 1, status_explanation: "A Mess") }

  shared_let(:work_package_parent) do
    create(:work_package, project:, category:, start_date: Date.yesterday, estimated_hours: 120,
                          remaining_hours: 80, due_date: 3.months.from_now, assigned_to: parent_assignee, version:)
  end

  shared_let(:work_package) do
    create(:work_package, responsible:, project:, category:, due_date: 1.month.from_now, assigned_to: assignee,
                          parent: work_package_parent, start_date: Time.zone.today, estimated_hours: 30,
                          remaining_hours: 25, version:)
  end

  shared_let(:string_custom_field) do
    create(:string_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.custom_fields << custom_field
    end
  end
  shared_let(:custom_field_not_on_type) do
    create(:string_wp_custom_field)
  end

  shared_let(:boolean_custom_field) do
    create(:boolean_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.custom_fields << custom_field

      work_package.send(:"custom_field_#{custom_field.id}=", false)
      work_package.save!
    end
  end

  shared_let(:date_custom_field) do
    create(:date_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.custom_fields << custom_field

      work_package.send(:"custom_field_#{custom_field.id}=", "2025-10-03T13:37:00Z")
      work_package.save!
    end
  end

  shared_let(:mult_list_custom_field) do
    create(:multi_list_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.custom_fields << custom_field

      work_package.send(:"custom_field_#{custom_field.id}=", custom_field.possible_values.take(2))
      work_package.save!
    end
  end

  shared_let(:not_activated_custom_field) do
    create(:string_wp_custom_field).tap do |custom_field|
      work_package.type.custom_fields << custom_field
    end
  end

  described_class::BASE_ATTRIBUTE_TOKENS.each do |token|
    it "the attribute token named #{token.key} resolves successfully" do
      context = case token.key
                when /^parent_/
                  work_package_parent
                when /^project_/
                  project
                else
                  work_package
                end

      expect { token.call(context) }.not_to raise_error
      expect(token.call(context)).not_to be_nil
    end
  end

  describe "#partitioned_tokens_for_type" do
    subject { described_class.new.partitioned_tokens_for_type(work_package.type) }

    it "multi value fields are supported" do
      enabled, = subject
      token = enabled.detect do |t|
        t.key == :"custom_field_#{mult_list_custom_field.id}"
      end
      expect(token.call(work_package)).to eq("A, B")
    end

    it "supports boolean custom fields" do
      enabled, = subject
      token = enabled.detect do |t|
        t.key == :"custom_field_#{boolean_custom_field.id}"
      end

      expect(token.call(work_package)).to eq("false")
    end

    it "formats date custom fields with a default format" do
      enabled, = subject
      token = enabled.detect do |t|
        t.key == :"custom_field_#{date_custom_field.id}"
      end

      expect(token.call(work_package)).to eq("2025-10-03")
    end

    it "must return :attribute_not_available if custom field is not activated in project" do
      enabled, = subject
      token = enabled.detect do |t|
        t.key == :"custom_field_#{not_activated_custom_field.id}"
      end

      expect { token.call(work_package) }.not_to raise_error
      expect(token.call(work_package)).to eq(:attribute_not_available)
    end

    it "returns all possible tokens as enabled" do
      cf = string_custom_field
      enabled, = subject

      expect(enabled.first).to be_a(WorkPackageTypes::Patterns::AttributeToken)
      expect(detect(enabled, :project_status)&.label).to eq(Project.human_attribute_name(:status_code))
      expect(detect(enabled, :"custom_field_#{cf.id}")&.label).to eq(cf.name)
    end

    it "does not return possible tokens as disabled" do
      cf = string_custom_field
      _, disabled = subject

      expect(detect(disabled, :project_status)).to be_nil
      expect(detect(disabled, :"custom_field_#{cf.id}")).to be_nil
    end

    it "returns a token that's not on the correct type as disabled" do
      cf = custom_field_not_on_type
      enabled, disabled = subject
      expect(detect(enabled, :"custom_field_#{cf.id}")).to be_nil
      expect(detect(disabled, :"custom_field_#{cf.id}")&.label).to eq(cf.name)
    end

    context "when defining an instance date format", with_settings: { date_format: "%d.%m.%Y" } do
      it "formats date custom fields according to the instance date format" do
        enabled, = subject
        token = enabled.detect do |t|
          t.key == :"custom_field_#{date_custom_field.id}"
        end

        expect(token.call(work_package)).to eq("03.10.2025")
      end
    end
  end

  private

  def detect(tokens, key)
    tokens.detect { |t| t.key == key }
  end
end
