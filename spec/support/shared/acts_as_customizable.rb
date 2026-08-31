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

RSpec.shared_examples_for "acts_as_customizable included" do |admin_only_allowed:, comments:|
  describe "admin_only_custom_fields_allowed? instance and class methods" do
    let(:expectation) { admin_only_allowed ? be_truthy : be_falsey }

    describe ".admin_only_custom_fields_allowed?" do
      it { expect(described_class.admin_only_custom_fields_allowed?).to expectation }
    end

    describe "#admin_only_custom_fields_allowed?" do
      it { expect(model_instance.admin_only_custom_fields_allowed?).to expectation }
    end
  end

  describe "can_have_custom_comments? instance and class methods" do
    let(:expectation) { comments ? be_truthy : be_falsey }

    describe ".can_have_custom_comments?" do
      it { expect(described_class.can_have_custom_comments?).to expectation }
    end

    describe "#can_have_custom_comments?" do
      it { expect(model_instance.can_have_custom_comments?).to expectation }
    end
  end

  describe ".custom_field_class" do
    it "returns the corresponding CustomField subclass" do
      expect(described_class.custom_field_class)
        .to eq("#{described_class.name}CustomField".constantize)
    end
  end

  describe "#custom_field_changes" do
    context "when no custom field value exists" do
      before do
        model_instance.custom_values.destroy_all
      end

      it "returns no changes" do
        expect(model_instance.custom_field_changes).to be_empty
      end

      context "when a field value is set" do
        before do
          model_instance.custom_values.destroy_all
        end

        it "returns the field changes" do
          model_instance.custom_field_values = { custom_field.id => "test" }
          expect(model_instance.custom_field_changes)
            .to eq({ custom_field.attribute_name => [nil, "test"] })
        end
      end
    end

    context "when a field value is changed from nil" do
      it "returns the field changes" do
        model_instance.custom_field_values = { custom_field.id => "test" }
        expect(model_instance.custom_field_changes)
          .to eq({ custom_field.attribute_name => [nil, "test"] })
      end
    end

    context "when a field value is changed from a string" do
      before do
        model_instance.custom_field_values = { custom_field.id => "test" }
        model_instance.save
      end

      it "returns the field changes" do
        model_instance.custom_field_values = { custom_field.id => "test2" }
        expect(model_instance.custom_field_changes)
          .to eq({ custom_field.attribute_name => ["test", "test2"] })
      end
    end

    context "when a field is set to the same value (unchanged)" do
      before do
        model_instance.custom_field_values = { custom_field.id => "test" }
        model_instance.save
      end

      it "returns no changes" do
        model_instance.custom_field_values = { custom_field.id => "test" }
        expect(model_instance.custom_field_changes).to be_empty
      end
    end

    context "when a field value is changed to nil" do
      before do
        model_instance.custom_field_values = { custom_field.id => "test" }
        model_instance.save
      end

      it "returns the field changes" do
        model_instance.custom_field_values = { custom_field.id => nil }
        expect(model_instance.custom_field_changes)
          .to eq({ custom_field.attribute_name => ["test", nil] })
      end
    end

    context "with a default value" do
      let(:custom_field) { create(:string_wp_custom_field, default_value: "foobar") }

      it "returns no changes" do
        expect(model_instance.custom_field_changes).to be_empty
      end
    end

    context "with a bool custom_field having a default value" do
      let(:custom_field) { create(:boolean_wp_custom_field, default_value: "0") }

      it "returns no changes" do
        expect(model_instance.custom_field_changes).to be_empty
      end
    end

    if comments
      context "when a comment is changed" do
        before { model_instance.custom_comments = { custom_field.id => "text" } }

        it "includes comment changes" do
          expect(model_instance.custom_field_changes)
            .to include(custom_field.comment_attribute_name => [nil, "text"])
        end
      end
    end
  end

  describe "#custom_values_to_validate" do
    context "for an existing model_instance" do
      subject { model_instance.custom_values_to_validate }

      it "returns an empty array when not explicitly set" do
        expect(subject).to eq([])
      end

      it "returns an empty array set via the setter" do
        model_instance.custom_values_to_validate = []
        expect(subject).to eq([])
      end

      it "returns the values set via the setter" do
        custom_value = model_instance.custom_field_values.first
        model_instance.custom_values_to_validate = custom_value

        expect(subject).to contain_exactly(custom_value)
      end

      it "allows appending values using << operator" do
        custom_value = model_instance.custom_field_values.first

        # Start with empty array
        model_instance.custom_values_to_validate = []
        expect(model_instance.custom_values_to_validate).to eq([])

        # Append using << operator
        model_instance.custom_values_to_validate << custom_value
        expect(model_instance.custom_values_to_validate).to contain_exactly(custom_value)

        # Append another value
        another_value = model_instance.custom_field_values.last
        model_instance.custom_values_to_validate << another_value
        expect(model_instance.custom_values_to_validate).to contain_exactly(custom_value, another_value)
      end

      it "allows appending values using push method" do
        custom_value = model_instance.custom_field_values.first
        another_value = model_instance.custom_field_values.last

        # Start with empty array
        model_instance.custom_values_to_validate = []

        # Append using push method
        model_instance.custom_values_to_validate.push(custom_value, another_value)
        expect(model_instance.custom_values_to_validate).to contain_exactly(custom_value, another_value)
      end
    end

    context "for a new model_instance" do
      subject { new_model_instance.custom_values_to_validate }

      it "returns custom_field_values when not explicitly set" do
        expect(subject).to contain_exactly(
          an_instance_of(CustomValue).and(having_attributes(custom_field_id: custom_field.id))
        )
      end

      it "returns and empty array" do
        new_model_instance.deactivate_custom_field_validations!

        expect(subject).to be_empty
      end

      it "returns the values set via the setter" do
        custom_value = new_model_instance.custom_field_values.first
        new_model_instance.custom_values_to_validate = custom_value

        expect(subject).to contain_exactly(
          an_instance_of(CustomValue).and(having_attributes(custom_field_id: custom_field.id))
        )
      end
    end
  end

  describe "#valid?" do
    shared_examples_for "is valid" do
      it { is_expected.to be_valid(:saving_custom_fields) }
    end

    shared_examples_for "has a validation error on a required custom field" do
      it "is expected to have a validation error" do
        expect(subject).not_to be_valid(:saving_custom_fields)
        expect(subject.errors.symbols_for(custom_field.attribute_getter))
          .to include :blank
      end
    end

    context "with a saved model_instance" do
      subject { model_instance }

      context "with no required custom fields" do
        it_behaves_like "is valid"
      end

      context "with a required custom field" do
        before do
          custom_field.update(is_required: true)
        end

        context "and the custom_values_to_validate is not set" do
          it_behaves_like "is valid"
        end

        context "and the custom_values_to_validate is set to the custom value" do
          before do
            subject.custom_values_to_validate = subject.custom_field_values.first
          end

          it_behaves_like "has a validation error on a required custom field"
        end

        context "and the custom_values_to_validate is set to be empty" do
          before do
            subject.custom_values_to_validate = []
          end

          it_behaves_like "is valid"
        end
      end
    end

    context "with a new_model_instance" do
      subject { new_model_instance }

      context "with no required custom fields" do
        it_behaves_like "is valid"
      end

      context "with a required custom field" do
        before do
          custom_field.update(is_required: true)
        end

        context "and the custom_values_to_validate is not set" do
          it_behaves_like "has a validation error on a required custom field"
        end

        context "and the custom_values_to_validate is set to the custom value" do
          before do
            subject.custom_values_to_validate = subject.custom_field_values.first
          end

          it_behaves_like "has a validation error on a required custom field"
        end

        context "and the custom_values_to_validate is set to be empty" do
          before do
            subject.custom_values_to_validate = []
          end

          it_behaves_like "is valid"
        end
      end
    end
  end

  describe "has_many :custom_comments" do
    if comments
      it { is_expected.to have_many(:custom_comments).dependent(:delete_all).autosave(true) }
    else
      # TODO: maybe better to find a way to write `.not_to have_relation(:custom_comments)`?
      it { is_expected.not_to have_many(:custom_comments) }
    end
  end

  describe "#custom_comments=" do
    if comments
      before do
        create(:custom_comment, customized: model_instance, custom_field:, text: "foo")
      end

      context "when passed a Hash" do
        context "with new custom field" do
          let(:another_custom_field) { create(:custom_field) }

          it "creates a new comment" do
            model_instance.update!(custom_comments: { another_custom_field.id => "bar" })

            expect(model_instance.reload.custom_comments).to contain_exactly(
              have_attributes(custom_field:, text: "foo"),
              have_attributes(custom_field: another_custom_field, text: "bar")
            )
          end

          it "does nothing when text is blank" do
            model_instance.update!(custom_comments: { another_custom_field.id => "" })

            expect(model_instance.reload.custom_comments.sole).to have_attributes(custom_field:, text: "foo")
          end
        end

        context "with commented custom field" do
          it "updates the existing comment" do
            model_instance.update!(custom_comments: { custom_field.id => "baz" })

            expect(model_instance.reload.custom_comments.sole).to have_attributes(custom_field:, text: "baz")
          end

          it "destroys the comment when text is blank" do
            model_instance.update!(custom_comments: { custom_field.id => "" })

            expect(model_instance.reload.custom_comments).to be_empty
          end
        end
      end

      context "when passed an Array" do
        it "replaces the comments collection" do
          model_instance.update!(custom_comments: [build(:custom_comment, custom_field:, text: "moin")])

          expect(model_instance.reload.custom_comments.sole).to have_attributes(custom_field:, text: "moin")
        end
      end

      context "when passed an invalid type" do
        it "raises ArgumentError" do
          expect { model_instance.custom_comments = "invalid" }
            .to raise_error(ArgumentError, /Expected an Array or Hash/)
        end
      end
    else
      it "raises ArgumentError" do
        expect { model_instance.custom_comments = [] }
          .to raise_error(ArgumentError, /Comments are not enabled for this customizable model/)
      end
    end
  end

  describe "#custom_comment_for" do
    if comments
      context "when no comment exists for the custom field" do
        it "returns nil" do
          expect(model_instance.custom_comment_for(custom_field)).to be_nil
        end
      end

      context "when a comment exists for the custom field" do
        let!(:comment) { create(:custom_comment, customized: model_instance, custom_field: custom_field) }

        it "returns the matching comment" do
          expect(model_instance.reload.custom_comment_for(custom_field)).to eq(comment)
        end
      end
    else
      context "even when a comment exists for the custom field" do
        it "returns nil" do
          create(:custom_comment, customized: model_instance, custom_field: custom_field)

          expect(model_instance.reload.custom_comment_for(custom_field)).to be_nil
        end
      end
    end
  end

  describe "#custom_comment_changes" do
    if comments
      before do
        create(:custom_comment, customized: model_instance, custom_field:, text: "foo")
      end

      context "when no comments are changed" do
        it "returns an empty hash" do
          expect(model_instance.custom_comment_changes).to eq({})
        end
      end

      context "with new custom field" do
        let(:another_custom_field) { create(:custom_field) }

        it "returns the comment change" do
          model_instance.custom_comments = { another_custom_field.id => "bar" }

          expect(model_instance.custom_comment_changes)
            .to eq({ another_custom_field.comment_attribute_name => [nil, "bar"] })
        end

        it "returns empty hash when text is blank" do
          model_instance.custom_comments = { another_custom_field.id => "" }

          expect(model_instance.custom_comment_changes).to eq({})
        end
      end

      context "with commented custom field" do
        it "returns the comment change" do
          model_instance.custom_comments = { custom_field.id => "baz" }

          expect(model_instance.custom_comment_changes)
            .to eq({ custom_field.comment_attribute_name => ["foo", "baz"] })
        end

        it "returns the comment change when text is blank" do
          model_instance.custom_comments = { custom_field.id => "" }

          expect(model_instance.custom_comment_changes)
            .to eq({ custom_field.comment_attribute_name => ["foo", nil] })
        end

        it "returns empty hash when text is set to the same value" do
          model_instance.custom_comments = { custom_field.id => "foo" }

          expect(model_instance.custom_comment_changes).to eq({})
        end
      end
    else
      it "returns an empty hash" do
        expect(model_instance.custom_comment_changes).to eq({})
      end
    end
  end

  describe "#custom_comment_<id>" do
    it "responds to the comment getter" do
      expect(model_instance).to respond_to(custom_field.comment_attribute_getter)
    end

    if comments
      it "returns nil when no comment exists" do
        expect(model_instance.send(custom_field.comment_attribute_getter)).to be_nil
      end

      context "when a comment exists" do
        it "returns the comment text" do
          create(:custom_comment, customized: model_instance, custom_field: custom_field, text: "hello, world!")

          expect(model_instance.reload.send(custom_field.comment_attribute_getter)).to eq("hello, world!")
        end
      end
    else
      context "even when a comment exists for the custom field" do
        it "returns nil" do
          create(:custom_comment, customized: model_instance, custom_field: custom_field)

          expect(model_instance.reload.send(custom_field.comment_attribute_getter)).to be_nil
        end
      end
    end
  end

  describe "#custom_comment_<id>=" do
    it "responds to the comment setter" do
      expect(model_instance).to respond_to(custom_field.comment_attribute_setter)
    end

    if comments
      it "sets the comment text" do
        model_instance.send(custom_field.comment_attribute_setter, "foo")
        model_instance.save!

        expect(model_instance.reload.custom_comments.sole).to have_attributes(custom_field:, text: "foo")
      end
    else
      it "raises ArgumentError" do
        expect { model_instance.send(custom_field.comment_attribute_setter, "foo") }
          .to raise_error(ArgumentError, /Comments are not enabled for this customizable model/)
      end
    end
  end
end
