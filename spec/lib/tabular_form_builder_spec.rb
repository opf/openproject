#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'
require 'ostruct'

TestViewHelper = Class.new(ActionView::Base)

describe TabularFormBuilder do
  include Capybara::RSpecMatchers

  let(:helper)   { TestViewHelper.new }
  let(:resource) {
    FactoryGirl.build(:user,
                      firstname:  'JJ',
                      lastname:   'Abrams',
                      login:      'lost',
                      mail:       'jj@lost-mail.com',
                      failed_login_count: 45)
  }
  let(:builder)  { TabularFormBuilder.new(:user, resource, helper, {}, nil) }

  describe '#text_field' do
    let(:options) { { title: 'Name', class: 'custom-class' } }

    subject(:output) {
      builder.text_field :name, options
    }

    it_behaves_like 'labelled by default'

    context 'with single_locale option' do
      let(:options)   { { single_locale: true } }
      let(:resource)  { FactoryGirl.build(:custom_field) }

      it_behaves_like 'wrapped in field-container by default'
      it_behaves_like 'wrapped in container', 'text-field-container'

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <input class="form--text-field"
            id="user_translations_attributes_0_name"
            name="user[translations_attributes][0][name]" size="30" type="text" />
        }).at_path('input:first-child')
      end
    end

    context 'with multi_locale option' do
      let(:options)   { { multi_locale: true } }
      let(:resource)  { FactoryGirl.build(:custom_field) }

      it_behaves_like 'wrapped in field-container by default'
      it_behaves_like 'wrapped in container', 'text-field-container'

      before do
        allow(Setting).to receive(:available_languages).and_return([:en])
      end

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <input class="form--text-field"
            id="user_translations_attributes_0_name"
            name="user[translations_attributes][0][name]" size="30" type="text" />
        }).at_path('input:first-child')
      end

      it 'should output select' do
        expect(output).to have_selector 'select.locale_selector > option', count: 1
      end

      it 'should have a link to add a locale' do
        expect(output).to be_html_eql(%{
          <a class="form--field-extra-actions add_locale" href="#">Add</a>
        }).at_path('body > a')
      end
    end

    context 'without locale' do
      it_behaves_like 'wrapped in field-container by default'
      it_behaves_like 'wrapped in container', 'text-field-container'

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <input class="custom-class form--text-field"
            id="user_name" name="user[name]" size="30" title="Name" type="text"
            value="JJ Abrams" />
        }).at_path('input')
      end
    end

    context 'with affixes' do
      context 'with a prefix' do
        let(:options) { { title: 'Name', prefix: %{<span style="color:red">Prefix</span>} } }

        it 'should output elements' do
          expect(output).to be_html_eql(%{
            <span class="form--field-affix"><span style="color:red">Prefix</span></span>
            <span class="form--text-field-container">
              <input class="form--text-field"
                id="user_name" name="user[name]" size="30" title="Name" type="text"
                value="JJ Abrams" />
            </span>
          }).within_path('span.form--field-container')
        end
      end

      context 'with a suffix' do
        let(:options) { { title: 'Name', suffix: %{<span style="color:blue">Suffix</span>} } }

        it 'should output elements' do
          expect(output).to be_html_eql(%{
            <span class="form--text-field-container">
              <input class="form--text-field"
                id="user_name" name="user[name]" size="30" title="Name" type="text"
                value="JJ Abrams" />
            </span>
            <span class="form--field-affix"><span style="color:blue">Suffix</span></span>
          }).within_path('span.form--field-container')
        end
      end

      context 'with both prefix and suffix' do
        let(:options) {
          {
            title: 'Name',
            prefix: %{<span style="color:yellow">PREFIX</span>},
            suffix: %{<span style="color:green">SUFFIX</span>}
          } }

        it 'should output elements' do
          expect(output).to be_html_eql(%{
            <span class="form--field-affix"><span style="color:yellow">PREFIX</span></span>
            <span class="form--text-field-container">
              <input class="form--text-field"
                id="user_name" name="user[name]" size="30" title="Name" type="text"
                value="JJ Abrams" />
            </span>
            <span class="form--field-affix"><span style="color:green">SUFFIX</span></span>
          }).within_path('span.form--field-container')
        end
      end
    end
  end

  describe '#text_area' do
    let(:options) { { title: 'Name', class: 'custom-class' } }

    subject(:output) {
      builder.text_area :name, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-area-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <textarea class="custom-class form--text-area" cols="40" id="user_name"
          name="user[name]" rows="20" title="Name">
JJ Abrams</textarea>
      }).at_path('textarea')
    end
  end

  describe '#select' do
    let(:options) { { title: 'Name' } }
    let(:html_options) { { class: 'custom-class' } }

    subject(:output) {
      builder.select :name, '<option value="33">FUN</option>'.html_safe, options, html_options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'select-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <select class="custom-class form--select"
          id="user_name" name="user[name]"><option value="33">FUN</option></select>
      }).at_path('select')
    end
  end

  describe '#collection_select' do
    let(:options) { { title: 'Name' } }
    let(:html_options) { { class: 'custom-class' } }

    subject(:output) {
      builder.collection_select :name, [
        OpenStruct.new(id: 56, name: 'Diana'),
        OpenStruct.new(id: 46, name: 'Ricky'),
        OpenStruct.new(id: 33, name: 'Jonas')
      ], :id, :name, options, html_options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'select-container'

    it 'should output element' do
      expect(output).to have_selector 'select.custom-class.form--select > option', count: 3
      expect(output).to have_selector 'option:first[value="56"]'
      expect(output).to have_text 'Jonas'
    end
  end

  describe '#date_select' do
    let(:options) { { title: 'Last logged in on' } }

    subject(:output) {
      builder.date_select :last_login_on, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'

    it 'should output element' do
      expect(output).to have_selector 'select', count: 3
      expect(output).to have_selector 'select:nth-of-type(2) > option', count: 12
      expect(output).to have_selector 'select:last > option', count: 31
    end
  end

  describe '#check_box' do
    let(:options) { { title: 'Name', class: 'custom-class' } }

    subject(:output) {
      builder.check_box :first_login, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'check-box-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--check-box"
          id="user_first_login" name="user[first_login]" title="Name" type="checkbox"
          value="1" />
      }).at_path('input:nth-of-type(2)')
    end
  end

  describe '#collection_check_box' do
    let(:options) { {} }

    subject(:output) {
      builder.collection_check_box :enabled_module_names,
                                   :repositories,
                                   true,
                                   'name',
                                   options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'check-box-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input checked="checked"
               class="form--check-box"
               id="user_enabled_module_names_repositories"
               name="user[enabled_module_names][]"
               type="checkbox"
               value="repositories" />
      }).at_path('input:nth-of-type(2)')
    end
  end

  describe '#radio_button' do
    let(:options) { { title: 'Name', class: 'custom-class' } }

    subject(:output) {
      builder.radio_button :name, 'John', options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in container'
    it_behaves_like 'wrapped in container', 'radio-button-container'

    it 'should output element' do
      expect(output).to include %{
        <input class="custom-class form--radio-button"
               id="user_name_john"
               name="user[name]"
               title="Name"
               type="radio"
               value="John" />
      }.squish
    end
  end

  describe '#number_field' do
    let(:options) { { title: 'Bad logins', class: 'custom-class' } }

    subject(:output) {
      builder.number_field :failed_login_count, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -number"
          id="user_failed_login_count" name="user[failed_login_count]" title="Bad logins"
          type="number" value="45" />
      }).at_path('input')
    end
  end

  describe '#range_field' do
    let(:options) { { title: 'Bad logins', class: 'custom-class' } }

    subject(:output) {
      builder.range_field :failed_login_count, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'range-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--range-field"
          id="user_failed_login_count" name="user[failed_login_count]" title="Bad logins"
          type="range" value="45" />
      }).at_path('input')
    end
  end

  describe '#search_field' do
    let(:options) { { title: 'Search name', class: 'custom-class' } }

    subject(:output) {
      builder.search_field :name, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'search-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--search-field" id="user_name"
          name="user[name]" size="30" title="Search name" type="search"
          value="JJ Abrams" />
      }).at_path('input')
    end
  end

  describe '#email_field' do
    let(:options) { { title: 'Email', class: 'custom-class' } }

    subject(:output) {
      builder.email_field :mail, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -email"
          id="user_mail" name="user[mail]" size="30" title="Email" type="email"
          value="jj@lost-mail.com" />
      }).at_path('input')
    end
  end

  describe '#telephone_field' do
    let(:options) { { title: 'Not really email', class: 'custom-class' } }

    subject(:output) {
      builder.telephone_field :mail, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -telephone"
          id="user_mail" name="user[mail]" size="30" title="Not really email"
          type="tel" value="jj@lost-mail.com" />
      }).at_path('input')
    end
  end

  describe '#password_field' do
    let(:options) { { title: 'Not really password', class: 'custom-class' } }

    subject(:output) {
      builder.password_field :login, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -password"
          id="user_login" name="user[login]" size="30" title="Not really password"
          type="password" />
      }).at_path('input')
    end
  end

  describe '#file_field' do
    let(:options) { { title: 'Not really file', class: 'custom-class' } }

    subject(:output) {
      builder.file_field :name, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'file-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--file-field"
          id="user_name" name="user[name]" title="Not really file" type="file" />
      }).at_path('input')
    end
  end

  describe '#url_field' do
    let(:options) { { title: 'Not really file', class: 'custom-class' } }

    subject(:output) {
      builder.url_field :name, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -url"
          id="user_name" name="user[name]" size="30" title="Not really file"
          type="url" value="JJ Abrams" />
      }).at_path('input')
    end
  end

  describe '#submit' do
    subject(:output) {
      builder.submit
    }

    it_behaves_like 'not labelled'
    it_behaves_like 'not wrapped in container'
    it_behaves_like 'not wrapped in container', 'submit-container'

    it 'should output element' do
      expect(output).to be_html_eql %{<input name="commit" type="submit" value="Create User" />}
    end
  end

  describe '#button' do
    subject(:output) {
      builder.button
    }

    it_behaves_like 'not labelled'
    it_behaves_like 'not wrapped in container'
    it_behaves_like 'not wrapped in container', 'button-container'

    it 'should output element' do
      expect(output).to be_html_eql %{<button name="button" type="submit">Create User</button>}
    end
  end

  describe '#label' do
    subject(:output) { builder.label :name }

    it 'should output element' do
      expect(output).to be_html_eql %{
        <label class="form--label"
               for="user_name"
               title="Name">
               Name
        </label>
      }
    end

    describe 'with existing attributes' do
      subject(:output) { builder.label :name, 'Fear', class: 'sharknado', title: 'Fear' }

      it 'should keep associated classes' do
        expect(output).to be_html_eql %{
          <label class="sharknado form--label" for="user_name" title="Fear">Fear</label>
        }
      end
    end

    describe 'when using it without ActiveModel' do
      let(:resource) { OpenStruct.new name: 'Deadpool' }

      it 'should fall back to the method name' do
        expect(output).to be_html_eql %{
          <label class="form--label" for="user_name" title="Name">Name</label>
        }
      end
    end
  end

  # test the label that is generated for various field types
  describe 'labels for fields' do
    let(:options) { {} }
    shared_examples_for "generated label" do
      def expected_label_like(expected_title, expected_classes = 'form--label')
        expect(output).to be_html_eql(%{
          <label class="#{expected_classes}"
                 for="user_name"
                 title="#{expected_title}">
            #{expected_title}
          </label>
        }).at_path('label')
      end

      context 'with a label specified as string' do
        let(:text) { "My own label" }

        before do
          options[:label] = text
        end

        it 'uses the label' do
          expected_label_like(text)
        end
      end

      context 'with a label specified as symbol' do
        let(:text) { :name }

        before do
          options[:label] = text
        end

        it 'uses the label' do
          expected_label_like(I18n.t(text))
        end
      end

      context 'without ActiveModel and specified label' do
        let(:resource) { OpenStruct.new name: 'Deadpool' }

        it 'falls back to the I18n name' do
          expected_label_like(I18n.t(:name))
        end
      end

      context 'with ActiveModel and withouth specified label' do
        let(:resource) {
          FactoryGirl.build_stubbed(:user,
                                    firstname:  'JJ',
                                    lastname:   'Abrams',
                                    login:      'lost',
                                    mail:       'jj@lost-mail.com',
                                    failed_login_count: 45)
        }

        it 'uses the human attibute name' do
          expected_label_like(User.human_attribute_name(:name))
        end
      end

      context 'when required, with a label specified as symbol' do
        let(:text) { :name }

        before do
          options[:label] = text
          options[:required] = true
        end

        it 'uses the label' do
          expected_label_like(I18n.t(:name), 'form--label -required')
        end
      end
    end

    %w{ text_field
        text_area
        check_box
        password_field }.each do |input_type|
      context "for #{input_type}" do
        subject(:output) {
          builder.send(input_type, :name, options)
        }

        it_behaves_like "generated label"
      end
    end

    context "for select" do
      subject(:output) {
        builder.select :name, [], options
      }

      it_behaves_like "generated label"
    end

  end
end
