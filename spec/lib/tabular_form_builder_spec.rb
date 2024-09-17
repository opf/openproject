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
require "ostruct"

RSpec.describe TabularFormBuilder do
  include Capybara::RSpecMatchers

  let(:helper) { ActionView::Base.new(ActionView::LookupContext.new(""), {}, nil) }
  let(:resource) do
    build(:user,
          firstname: "JJ",
          lastname: "Abrams",
          login: "lost",
          mail: "jj@lost-mail.com",
          failed_login_count: 45)
  end
  let(:builder) { TabularFormBuilder.new(:user, resource, helper, {}) }

  describe "#text_field" do
    let(:options) { { title: "Name", class: "custom-class" } }

    subject(:output) do
      builder.text_field :name, options
    end

    it_behaves_like "labelled by default"

    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "text-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field"
          id="user_name" name="user[name]" title="Name" type="text"
          value="JJ Abrams" />
      }).at_path("input")
    end

    context "with help text" do
      let(:options) { { title: "Name", class: "custom-class", help_text: { attribute: "foo", "attribute-scope": "bar" } } }

      it "outputs a label with an attribute-help-text tag" do
        expect(output).to be_html_eql(%{
          <label class="form--label"
                 for="user_name"
                 title="Name">
            Name
            <attribute-help-text data-attribute="foo"
                                 data-attribute-scope="bar">
            </attribute-help-text>
          </label>
        }).at_path("label")
      end
    end

    context "with affixes" do
      let(:random_id) { "random_id" }

      before do
        allow(SecureRandom)
          .to receive(:uuid)
          .and_return(random_id)
      end

      context "with a prefix" do
        let(:options) { { title: "Name", prefix: %{<span style="color:red">Prefix</span>} } }

        it "outputs elements" do
          expect(output).to be_html_eql(%{
            <span class="form--field-affix"
                  id="#{random_id}"
                  aria-hidden="true">
              <span style="color:red">Prefix</span>
            </span>
            <span class="form--text-field-container">
              <input class="form--text-field"
                     id="user_name"
                     name="user[name]"
                     title="Name"
                     type="text"
                     value="JJ Abrams" />
            </span>
          }).within_path("span.form--field-container")
        end

        it "includes the prefix hidden in the label" do
          expect(output).to be_html_eql(%{
            <span class="hidden-for-sighted">
              <span style="color:red">Prefix</span>
            </span>
          }).within_path("label.form--label")
        end
      end

      context "with a suffix" do
        let(:options) { { title: "Name", suffix: %{<span style="color:blue">Suffix</span>} } }

        it "outputs elements" do
          expect(output).to be_html_eql(%{
            <span class="form--text-field-container">
              <input class="form--text-field"
                     id="user_name"
                     name="user[name]"
                     title="Name"
                     type="text"
                     aria-describedby="#{random_id}"
                     value="JJ Abrams" />
            </span>
            <span class="form--field-affix"
                  aria-hidden="true"
                  id="#{random_id}">
              <span style="color:blue">Suffix</span>
            </span>
          }).within_path("span.form--field-container")
        end
      end

      context "with both prefix and suffix" do
        let(:options) do
          {
            title: "Name",
            prefix: %{<span style="color:yellow">PREFIX</span>},
            suffix: %{<span style="color:green">SUFFIX</span>}
          }
        end

        it "outputs elements" do
          expect(output).to be_html_eql(%{
            <span class="form--field-affix"
                  id="#{random_id}"
                  aria-hidden="true">
              <span style="color:yellow">PREFIX</span>
            </span>
            <span class="form--text-field-container">
              <input class="form--text-field"
                     id="user_name"
                     name="user[name]"
                     title="Name"
                     type="text"
                     aria-describedby="#{random_id}"
                     value="JJ Abrams" />
            </span>
            <span class="form--field-affix"
                  aria-hidden="true"
                  id="#{random_id}">
              <span style="color:green">SUFFIX</span>
            </span>
          }).within_path("span.form--field-container")
        end

        it "includes the prefix hidden in the label" do
          expect(output).to be_html_eql(%{
            <span class="hidden-for-sighted">
              <span style="color:yellow">PREFIX</span>
            </span>
          }).within_path("label.form--label")
        end
      end
    end
  end

  describe "#text_area" do
    let(:options) { { title: "Name", class: "custom-class" } }

    subject(:output) do
      builder.text_area :name, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "text-area-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <textarea class="custom-class form--text-area" id="user_name"
          name="user[name]" title="Name">
JJ Abrams</textarea>
      }).at_path("textarea")
    end

    context "when requesting a text formatting wrapper" do
      let(:options) { { title: "Name", class: "custom-class", with_text_formatting: true } }

      context "an id is missing" do
        it "outputs the wysiwyg wrapper" do
          expect(output).to have_css "textarea"
          expect(output).to have_css "opce-ckeditor-augmented-textarea"
        end
      end

      context "with id present" do
        let(:options) { { id: "my-id", title: "Name", class: "custom-class", with_text_formatting: true } }

        it "outputs the wysiwyg wrapper" do
          expect(output).to have_css "textarea"
          expect(output).to have_css "opce-ckeditor-augmented-textarea"
        end
      end
    end
  end

  describe "#select" do
    let(:options) { { title: "Name" } }
    let(:html_options) { { class: "custom-class" } }

    subject(:output) do
      builder.select :name, '<option value="33">FUN</option>'.html_safe, options, html_options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "select-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <select class="custom-class form--select"
          id="user_name" name="user[name]"><option value="33">FUN</option></select>
      }).at_path("select")
    end
  end

  describe "#collection_select" do
    let(:options) { { title: "Name" } }
    let(:html_options) { { class: "custom-class" } }

    subject(:output) do
      builder.collection_select :name, [
        OpenStruct.new(id: 56, name: "Diana"),
        OpenStruct.new(id: 46, name: "Ricky"),
        OpenStruct.new(id: 33, name: "Jonas")
      ], :id, :name, options, html_options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "select-container"

    it "outputs element" do
      expect(output).to have_css "select.custom-class.form--select > option", count: 3
      expect(output).to have_css 'option:first[value="56"]'
      expect(output).to have_text "Jonas"
    end
  end

  describe "#date_picker" do
    let(:options) { { title: "Last logged in", name: "user[custom_field_values][12]" } }

    subject(:output) do
      builder.date_picker :last_login_on, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"

    it "outputs element" do
      expect(output).to have_css "opce-basic-single-date-picker"
      # Regression test, allow for the name to be passed through
      expect(output).to have_css "opce-basic-single-date-picker[data-name='\"#{options[:name]}\"']"
    end
  end

  describe "#date_select" do
    let(:options) { { title: "Last logged in on" } }

    subject(:output) do
      builder.date_select :last_login_on, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"

    it "outputs element" do
      expect(output).to have_css "select", count: 3
      expect(output).to have_css "select:nth-of-type(2) > option", count: 12
      expect(output).to have_css "select:last > option", count: 31
    end
  end

  describe "#check_box" do
    let(:options) { { title: "Name", class: "custom-class" } }

    subject(:output) do
      builder.check_box :first_login, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "check-box-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--check-box"
          id="user_first_login" name="user[first_login]" title="Name" type="checkbox"
          value="1" />
      }).at_path("input:nth-of-type(2)")
    end
  end

  describe "#collection_check_box" do
    let(:options) { {} }

    subject(:output) do
      builder.collection_check_box :enabled_module_names,
                                   :repositories,
                                   true,
                                   "name",
                                   options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "check-box-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input checked="checked"
               class="form--check-box"
               id="user_enabled_module_names_repositories"
               name="user[enabled_module_names][]"
               type="checkbox"
               value="repositories" />
      }).at_path("input:nth-of-type(2)")
    end
  end

  describe "#radio_button" do
    let(:options) { { title: "Name", class: "custom-class" } }

    subject(:output) do
      builder.radio_button :name, "John", options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in container"
    it_behaves_like "wrapped in container", "radio-button-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--radio-button"
               id="user_name_john"
               name="user[name]"
               title="Name"
               type="radio"
               value="John" />
      }).at_path("input")
    end
  end

  describe "#number_field" do
    let(:options) { { title: "Bad logins", class: "custom-class" } }

    subject(:output) do
      builder.number_field :failed_login_count, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "text-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -number"
          id="user_failed_login_count" name="user[failed_login_count]" title="Bad logins"
          type="number" value="45" />
      }).at_path("input")
    end
  end

  describe "#range_field" do
    let(:options) { { title: "Bad logins", class: "custom-class" } }

    subject(:output) do
      builder.range_field :failed_login_count, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "range-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--range-field"
          id="user_failed_login_count" name="user[failed_login_count]" title="Bad logins"
          type="range" value="45" />
      }).at_path("input")
    end
  end

  describe "#search_field" do
    let(:options) { { title: "Search name", class: "custom-class" } }

    subject(:output) do
      builder.search_field :name, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "search-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--search-field" id="user_name"
          name="user[name]" title="Search name" type="search"
          value="JJ Abrams" />
      }).at_path("input")
    end
  end

  describe "#email_field" do
    let(:options) { { title: "Email", class: "custom-class" } }

    subject(:output) do
      builder.email_field :mail, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "text-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -email"
          id="user_mail" name="user[mail]" title="Email" type="email"
          value="jj@lost-mail.com" />
      }).at_path("input")
    end
  end

  describe "#telephone_field" do
    let(:options) { { title: "Not really email", class: "custom-class" } }

    subject(:output) do
      builder.telephone_field :mail, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "text-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -telephone"
          id="user_mail" name="user[mail]" title="Not really email"
          type="tel" value="jj@lost-mail.com" />
      }).at_path("input")
    end
  end

  describe "#password_field" do
    let(:options) { { title: "Not really password", class: "custom-class" } }

    subject(:output) do
      builder.password_field :login, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "text-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -password"
          id="user_login" name="user[login]" title="Not really password"
          type="password" />
      }).at_path("input")
    end
  end

  describe "#file_field" do
    let(:options) { { title: "Not really file", class: "custom-class" } }

    subject(:output) do
      builder.file_field :name, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "file-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--file-field"
          id="user_name" name="user[name]" title="Not really file" type="file" />
      }).at_path("input")
    end
  end

  describe "#url_field" do
    let(:options) { { title: "Not really file", class: "custom-class" } }

    subject(:output) do
      builder.url_field :name, options
    end

    it_behaves_like "labelled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "text-field-container"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -url"
          id="user_name" name="user[name]" title="Not really file"
          type="url" value="JJ Abrams" />
      }).at_path("input")
    end
  end

  describe "#submit" do
    subject(:output) do
      Capybara::Node::Simple.new(builder.submit)
    end

    it_behaves_like "not labelled"
    it_behaves_like "not wrapped in container"
    it_behaves_like "not wrapped in container", "submit-container"

    it "outputs element" do
      expect(output).to have_css("input[name=commit]")
    end
  end

  describe "#button" do
    subject(:output) do
      builder.button
    end

    it_behaves_like "not labelled"
    it_behaves_like "not wrapped in container"
    it_behaves_like "not wrapped in container", "button-container"

    it "outputs element" do
      expect(output).to be_html_eql %{<button name="button" type="submit">Create User</button>}
    end
  end

  describe "#label" do
    subject(:output) { builder.label :name }

    it "outputs element" do
      expect(output).to be_html_eql %{
        <label class="form--label"
               for="user_name"
               title="Name">
               Name
        </label>
      }
    end

    describe "with existing attributes" do
      subject(:output) { builder.label :name, "Fear", class: "sharknado", title: "Fear" }

      it "keeps associated classes" do
        expect(output).to be_html_eql %{
          <label class="sharknado form--label" for="user_name" title="Fear">Fear</label>
        }
      end
    end

    describe "when using it without ActiveModel" do
      let(:resource) { OpenStruct.new name: "Deadpool" }

      it "falls back to the method name" do
        expect(output).to be_html_eql %{
          <label class="form--label" for="user_name" title="Name">Name</label>
        }
      end
    end
  end

  # test the label that is generated for various field types
  describe "labels for fields" do
    let(:options) { {} }

    shared_examples_for "generated label" do
      def expected_label_like(expected_title, expected_classes = "form--label")
        expect(output).to be_html_eql(%{
          <label class="#{expected_classes}"
                 for="user_name"
                 title="#{expected_title}">
            #{expected_title}
          </label>
        }).at_path("label")
      end

      def expected_form_label_like(expected_title, expected_classes = "form--label")
        expect(output).to be_html_eql(%{
          <label class="#{expected_classes}"
                 for="user_name"
                 title="#{expected_title}">
            #{expected_title}
          </label>
        }).at_path("label")
      end

      context "with a label specified as string" do
        let(:text) { "My own label" }

        before do
          options[:label] = text
        end

        it "uses the label" do
          expected_label_like(text)
        end
      end

      context "with a label specified as symbol" do
        let(:text) { :label_name }

        before do
          options[:label] = text
        end

        it "uses the label" do
          expected_label_like(I18n.t(text))
        end
      end

      context "without ActiveModel and specified label" do
        # This is a hypotethical resource that does not have an existing translation
        # key, therefore stubbing the translation is allowed.
        before do
          allow(I18n).to receive(:t).with(:name, scope: "user").and_return("Name")
        end

        let(:resource) { OpenStruct.new name: "Deadpool" }

        it "falls back to the I18n name" do
          expected_label_like(I18n.t(:name, scope: "user"))
        end
      end

      context "with ActiveModel and without specified label" do
        let(:resource) do
          build_stubbed(:user,
                        firstname: "JJ",
                        lastname: "Abrams",
                        login: "lost",
                        mail: "jj@lost-mail.com",
                        failed_login_count: 45)
        end

        it "uses the human attribute name" do
          expected_label_like(User.human_attribute_name(:name))
        end

        context "with erroneous field" do
          before do
            resource.errors.add(:name, :invalid)
            resource.errors.add(:name, :inclusion)
          end

          it "shows an appropriate error label" do
            expect(output).to have_css "label.-error",
                                       count: 1,
                                       text: "Name"
          end

          it "contains a specific error as a hidden sub-label" do
            expect(output).to have_css "label.-error p",
                                       count: 1,
                                       text: "This field is invalid: Name is invalid. " \
                                             "Name is not set to one of the allowed values."
          end
        end
      end

      context "when required, with a label specified as symbol" do
        let(:text) { :label_name }

        before do
          options[:label] = text
          options[:required] = true
        end

        it "uses the label" do
          expected_form_label_like(I18n.t(:label_name), "form--label")
        end
      end
    end

    %w{ text_field
        text_area
        check_box
        password_field }.each do |input_type|
      context "for #{input_type}" do
        subject(:output) do
          builder.send(input_type, :name, options)
        end

        it_behaves_like "generated label"
      end
    end

    context "for select" do
      subject(:output) do
        builder.select :name, [], options
      end

      it_behaves_like "generated label"
    end
  end
end
