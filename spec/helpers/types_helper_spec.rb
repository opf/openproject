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

RSpec.describe TypesHelper do
  let(:type) { build_stubbed(:type) }
  let(:variant) { build_stubbed(:type_variant, type:) }

  describe "#types_tabs" do
    subject(:tab_names) { helper.types_tabs.pluck(:name) }

    before do
      helper.instance_variable_set(:@type, type)
      helper.instance_variable_set(:@variant, addressed_variant)
    end

    context "with the type_variants feature enabled", with_flag: { type_variants: true } do
      context "when no variant is addressed" do
        let(:addressed_variant) { nil }

        it "offers the variants tab right after the defaults tab" do
          expect(tab_names).to include("variants")
          expect(tab_names.index("variants")).to eq(tab_names.index("defaults") + 1)
        end
      end

      context "when the base variant is addressed" do
        let(:addressed_variant) { build_stubbed(:type_variant, type:, is_default_variant: true) }

        it "offers the variants tab: the URL is about the type itself" do
          expect(tab_names).to include("variants")
        end
      end

      context "when a named variant is addressed" do
        let(:addressed_variant) { variant }

        it "omits the variants tab" do
          expect(tab_names).not_to include("variants")
        end
      end

      context "when a variant a project owns is addressed" do
        let(:addressed_variant) do
          build_stubbed(:project_owned_type_variant, type:, project: build_stubbed(:project))
        end

        # It is only ever used in the project owning it, so which projects use it is not a
        # question — for an administrator either, which is who sees this tab set.
        it "omits the projects tab" do
          expect(tab_names).not_to include("projects")
        end

        it "still offers the tabs that configure it" do
          expect(tab_names).to include("details", "defaults", "form_configuration")
        end
      end

      context "when a variant every project may use is addressed" do
        let(:addressed_variant) { variant }

        it "offers the projects tab" do
          expect(tab_names).to include("projects")
        end
      end
    end

    context "with the type_variants feature disabled", with_flag: { type_variants: false } do
      let(:addressed_variant) { nil }

      it "omits the variants tab" do
        expect(tab_names).not_to include("variants")
      end
    end
  end

  describe "#form_configuration_groups" do
    it "returns a Hash with the keys :actives and :inactives Arrays" do
      expect(helper.form_configuration_groups(variant)[:actives]).to be_an Array
      expect(helper.form_configuration_groups(variant)[:inactives]).to be_an Array
    end

    describe ":inactives" do
      subject { helper.form_configuration_groups(variant)[:inactives] }

      before do
        allow(variant)
          .to receive(:attribute_groups)
          .and_return [Type::AttributeGroup.new(variant, "group one", ["assignee"])]
      end

      it "contains Hashes ordered by key :translation" do
        # The first left over attribute should currently be "date"
        expect(subject.first[:translation]).to be_present
        expect(subject.first[:translation] <= subject.second[:translation]).to be_truthy
      end

      # The "assignee" is in "group one". It should not appear in :inactives.
      it "does not contain attributes that do not exist anymore" do
        expect(subject.pluck(:key)).not_to include "assignee"
      end
    end

    describe ":actives" do
      subject { helper.form_configuration_groups(variant)[:actives] }

      before do
        allow(variant)
          .to receive(:attribute_groups)
          .and_return [Type::AttributeGroup.new(variant, "group one", ["date"])]
      end

      it "has a proper structure" do
        # The group's name/key
        expect(subject.first[:key]).to eq "group one"
        expect(subject.first[:name]).to eq "group one"

        # The groups attributes
        expect(subject.first[:attributes]).to be_an Array
        expect(subject.first[:attributes].first[:key]).to eq "date"
        expect(subject.first[:attributes].first[:translation]).to eq "Date"
      end

      it "includes the key for built-in groups" do
        allow(variant)
          .to receive(:attribute_groups)
          .and_return [Type::AttributeGroup.new(variant, :details, ["date"])]

        expect(subject.first[:key]).to eq :details
      end

      it "carries no exclusion element key for attribute groups" do
        expect(subject.first[:element_key]).to be_nil
      end

      context "with a query group" do
        let(:query) { create(:query) }

        before do
          allow(variant)
            .to receive(:attribute_groups)
            .and_return [Type::QueryGroup.new(variant, "Related", query)]
        end

        it "carries the query key the group is excluded by" do
          expect(subject.first[:element_key]).to eq "query_#{query.id}"
        end
      end

      context "with a query group whose query was deleted" do
        before do
          allow(variant)
            .to receive(:attribute_groups)
            .and_return [Type::QueryGroup.new(variant, "Related", nil)]
        end

        it "renders without a query or an element key", :aggregate_failures do
          expect { subject }.not_to raise_error
          expect(subject.first[:element_key]).to be_nil
          expect(subject.first[:query]).to be_nil
        end
      end
    end

    describe "field_format_label" do
      subject(:groups) { helper.form_configuration_groups(variant) }

      before do
        allow(variant).to receive(:attribute_groups).and_return []
      end

      it "returns 'Builtin field' for built-in attributes" do
        builtin = groups[:inactives].find { |a| a[:key] == "date" }
        expect(builtin[:field_format_label]).to eq I18n.t("types.edit.form_configuration.builtin_field")
      end

      context "with a custom field" do
        let!(:custom_field) { create(:wp_custom_field, :string, name: "My CF") }

        it "returns the custom field format label" do
          cf_attr = groups[:inactives].find { |a| a[:key] == custom_field.attribute_name }
          expect(cf_attr[:field_format_label]).to eq I18n.t(:label_string)
        end
      end
    end
  end

  describe "#icon_for_type" do
    subject(:icon) { helper.icon_for_type(type) }

    context "with a milestone type" do
      let(:type) { build_stubbed(:type, is_milestone: true) }

      it "names the shape, which is otherwise the only milestone cue" do
        expect(icon).to have_css("span.color--milestone-icon[role='img'][title='Milestone']", visible: :all)
      end
    end

    context "with an ordinary type" do
      let(:type) { build_stubbed(:type, is_milestone: false) }

      it "stays decorative, since the type name follows in text" do
        expect(icon).to have_css("span.color--phase-icon[aria-hidden='true']", visible: :all)
        expect(icon).to have_no_css("span[title]", visible: :all)
      end
    end

    it "renders nothing without a type" do
      expect(helper.icon_for_type(nil)).to be_nil
    end
  end
end
