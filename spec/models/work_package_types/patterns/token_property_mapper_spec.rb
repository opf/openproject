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

  shared_let(:observed_version) { create(:version, project:) }

  shared_let(:observed_in_version_rows) do
    [work_package, work_package_parent].map do |wp|
      create(:work_package_version, work_package: wp, version: observed_version, kind: :observed_in)
    end
  end

  shared_let(:string_custom_field) do
    create(:string_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.default_variant.custom_fields << custom_field
    end
  end
  shared_let(:custom_field_not_on_type) do
    create(:string_wp_custom_field)
  end

  shared_let(:boolean_custom_field) do
    create(:boolean_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.default_variant.custom_fields << custom_field

      work_package.send(:"custom_field_#{custom_field.id}=", false)
      work_package.save!
    end
  end

  shared_let(:date_custom_field) do
    create(:date_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.default_variant.custom_fields << custom_field

      work_package.send(:"custom_field_#{custom_field.id}=", "2025-10-03T13:37:00Z")
      work_package.save!
    end
  end

  shared_let(:mult_list_custom_field) do
    create(:multi_list_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.default_variant.custom_fields << custom_field

      work_package.send(:"custom_field_#{custom_field.id}=", custom_field.possible_values.take(2))
      work_package.save!
    end
  end

  shared_let(:not_activated_custom_field) do
    create(:string_wp_custom_field).tap do |custom_field|
      work_package.type.default_variant.custom_fields << custom_field
    end
  end

  described_class::static_tokens.each do |token|
    it "the attribute token named #{token.key} resolves successfully" do
      context = case token.context
                when :parent
                  work_package_parent
                when :project
                  project
                else
                  work_package
                end

      expect { token.call(context, nil) }.not_to raise_error
      expect(token.call(context, nil)).not_to be_nil
    end
  end

  describe "#partitioned_tokens_for_type" do
    subject { described_class.new.partitioned_tokens_for_type(work_package.type_variant) }

    it "multi value fields are supported" do
      enabled, = subject
      token = enabled.detect do |t|
        t.key == :"custom_field_#{mult_list_custom_field.id}"
      end
      expect(token.call(work_package, nil)).to eq("A, B")
    end

    it "supports boolean custom fields" do
      enabled, = subject
      token = enabled.detect do |t|
        t.key == :"custom_field_#{boolean_custom_field.id}"
      end

      expect(token.call(work_package, nil)).to eq("false")
    end

    it "formats date custom fields with a default format" do
      enabled, = subject
      token = enabled.detect do |t|
        t.key == :"custom_field_#{date_custom_field.id}"
      end

      expect(token.call(work_package, nil)).to eq("2025-10-03")
    end

    it "must return :attribute_not_available if custom field is not activated in project" do
      enabled, = subject
      token = enabled.detect do |t|
        t.key == :"custom_field_#{not_activated_custom_field.id}"
      end

      expect { token.call(work_package, nil) }.not_to raise_error
      expect(token.call(work_package, nil)).to eq(:attribute_not_available)
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

        expect(token.call(work_package, nil)).to eq("03.10.2025")
      end
    end

    context "for a type" do
      let(:root_type) { create(:type, name: "Task") }
      let(:work_package_of_type) { build_stubbed(:work_package, type: root_type) }

      subject { described_class.new.partitioned_tokens_for_type(root_type.default_variant) }

      it "resolves the type token to the type's name" do
        enabled, = subject
        token = detect(enabled, :type)

        expect(token.call(work_package_of_type, nil)).to eq("Task")
      end
    end

    context "for versions" do
      shared_let(:second_version) { create(:version, project:) }

      before do
        create(:work_package_version, work_package:, version: second_version, kind: :target)
      end

      context "when work package multiple versions is active",
              with_settings: { work_package_multiple_versions: true } do
        it "renders an array of values" do
          enabled, = subject
          token = detect(enabled, :version)

          expect(token.call(work_package, nil)).to eq("#{version.name}, #{second_version.name}")
        end

        it "label is target versions" do
          enabled, = subject
          expect(detect(enabled, :version)&.label).to eq("Target versions")
        end
      end

      context "when work package multiple versions is not active",
              with_settings: { work_package_multiple_versions: false } do
        it "label is version" do
          enabled, = subject
          expect(detect(enabled, :version)&.label).to eq("Version")
        end
      end
    end

    context "for observed in versions" do
      shared_let(:second_observed_version) { create(:version, project:) }

      before do
        create(:work_package_version, work_package:, version: second_observed_version, kind: :observed_in)
      end

      it "renders an array of values" do
        enabled, = subject
        token = detect(enabled, :observed_in_versions)

        expect(token.call(work_package, nil).split(", "))
          .to contain_exactly(observed_version.name, second_observed_version.name)
      end

      it "resolves the parent token from the parent work package" do
        enabled, = subject
        token = detect(enabled, :parent_observed_in_versions)

        expect(token.call(work_package_parent, nil)).to eq(observed_version.name)
      end

      context "when work package multiple versions is active",
              with_settings: { work_package_multiple_versions: true } do
        it "label is observed in versions" do
          enabled, = subject
          expect(detect(enabled, :observed_in_versions)&.label).to eq("Observed in versions")
        end
      end

      context "when work package multiple versions is not active",
              with_settings: { work_package_multiple_versions: false } do
        it "label is observed in versions" do
          enabled, = subject
          expect(detect(enabled, :observed_in_versions)&.label).to eq("Observed in versions")
        end
      end
    end
  end

  private

  def detect(tokens, key)
    tokens.detect { |t| t.key == key }
  end
end
