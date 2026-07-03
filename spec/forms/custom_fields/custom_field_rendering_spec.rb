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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe CustomFields::CustomFieldRendering do
  let(:form_class) do
    Class.new do
      include CustomFields::CustomFieldRendering

      attr_reader :model
    end
  end

  let(:form_instance) { form_class.new }
  let(:model) { instance_double(ApplicationRecord) }
  let(:builder) { instance_double(ActionView::Helpers::FormBuilder) }

  before do
    allow(form_instance).to receive_messages(model:)
  end

  describe "#render_custom_fields" do
    describe "custom values" do
      let(:values_builder) { instance_double(ActionView::Helpers::FormBuilder) }
      let(:custom_field) { build(:custom_field, field_format:, multi_value:) }
      let(:extra_args) { { foo: "bar" } }

      before do
        allow(builder).to receive(:fields_for).with(:custom_field_values).and_yield(values_builder)
        allow(builder).to receive(:fields_for).with(:custom_comments)
        allow(form_instance).to receive_messages(
          custom_fields: [custom_field],
          additional_custom_field_input_arguments: extra_args
        )
      end

      context "for single value custom fields" do
        let(:multi_value) { false }

        {
          "string" => CustomFields::Inputs::String,
          "link" => CustomFields::Inputs::String,
          "text" => CustomFields::Inputs::Text,
          "int" => CustomFields::Inputs::Int,
          "float" => CustomFields::Inputs::Float,
          "hierarchy" => CustomFields::Inputs::SingleSelectList,
          "weighted_item_list" => CustomFields::Inputs::SingleSelectList,
          "list" => CustomFields::Inputs::SingleSelectList,
          "date" => CustomFields::Inputs::Date,
          "bool" => CustomFields::Inputs::Bool,
          "user" => CustomFields::Inputs::SingleUserSelectList,
          "version" => CustomFields::Inputs::SingleVersionSelectList,
          "calculated_value" => CustomFields::Inputs::CalculatedValue
        }.each do |format, input_class|
          context "for format '#{format}'" do
            let(:field_format) { format }

            it "renders using #{input_class}" do
              allow(input_class).to receive(:new)

              form_instance.render_custom_fields(form: builder)

              expect(input_class).to have_received(:new).with(
                values_builder,
                custom_field:,
                object: model,
                **extra_args
              )
            end
          end
        end

        context "for unsupported format" do
          let(:field_format) { "unknown" }

          it "raises an error" do
            expect do
              form_instance.render_custom_fields(form: builder)
            end.to raise_error("Unhandled custom field format unknown")
          end
        end
      end

      context "for multi value custom fields" do
        let(:multi_value) { true }

        {
          "hierarchy" => CustomFields::Inputs::MultiSelectList,
          "weighted_item_list" => CustomFields::Inputs::MultiSelectList,
          "list" => CustomFields::Inputs::MultiSelectList,
          "user" => CustomFields::Inputs::MultiUserSelectList,
          "version" => CustomFields::Inputs::MultiVersionSelectList
        }.each do |format, input_class|
          context "for format '#{format}'" do
            let(:field_format) { format }

            it "renders using #{input_class}" do
              allow(input_class).to receive(:new)

              form_instance.render_custom_fields(form: builder)

              expect(input_class).to have_received(:new).with(
                values_builder,
                custom_field:,
                object: model,
                **extra_args
              )
            end
          end
        end

        context "for unsupported format" do
          let(:field_format) { "unknown" }

          it "raises an error" do
            expect do
              form_instance.render_custom_fields(form: builder)
            end.to raise_error("Unhandled custom field format unknown")
          end
        end
      end
    end

    describe "comment fields" do
      let(:comments_builder) { instance_double(ActionView::Helpers::FormBuilder) }
      let(:custom_field) { build(:custom_field, :string) }
      let(:commentable_custom_field) { build(:custom_field, :string, :has_comment) }

      before do
        allow(builder).to receive(:fields_for).with(:custom_field_values)
        allow(builder).to receive(:fields_for).with(:custom_comments).and_yield(comments_builder)
        allow(form_instance).to receive_messages(custom_fields:, additional_custom_field_input_arguments: {})
        allow(CustomFields::CommentField).to receive(:new)
      end

      context "when a single custom field has a comment" do
        let(:custom_fields) { [commentable_custom_field] }

        it "renders a comment field with complete_label: false" do
          form_instance.render_custom_fields(form: builder)

          expect(CustomFields::CommentField).to have_received(:new).once
          expect(CustomFields::CommentField).to have_received(:new).with(
            comments_builder,
            custom_field: commentable_custom_field,
            object: model,
            complete_label: false
          )
        end
      end

      context "when a custom field does not have a comment" do
        let(:custom_fields) { [custom_field] }

        it "does not render a comment field" do
          form_instance.render_custom_fields(form: builder)

          expect(CustomFields::CommentField).not_to have_received(:new)
        end
      end

      context "when multiple custom fields have comments" do
        let(:custom_fields) { [custom_field, commentable_custom_field] }

        it "renders comment field only for commentable custom field with complete_label: true" do
          form_instance.render_custom_fields(form: builder)

          expect(CustomFields::CommentField).to have_received(:new).once
          expect(CustomFields::CommentField).to have_received(:new).with(
            comments_builder,
            custom_field: commentable_custom_field,
            object: model,
            complete_label: true
          )
        end
      end
    end
  end

  describe "#render_custom_field" do
    let(:values_builder) { instance_double(ActionView::Helpers::FormBuilder) }
    let(:custom_field) { build(:custom_field, :string) }

    before do
      allow(builder).to receive(:fields_for).with(:custom_field_values).and_yield(values_builder)
      allow(form_instance).to receive(:additional_custom_field_input_arguments).and_return({})
    end

    it "renders a single custom field input" do
      allow(CustomFields::Inputs::String).to receive(:new)

      form_instance.render_custom_field(form: builder, custom_field:)

      expect(CustomFields::Inputs::String).to have_received(:new).with(
        values_builder,
        custom_field:,
        object: model
      )
    end
  end
end
