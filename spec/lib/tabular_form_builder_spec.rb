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
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'

    it 'should output element' do
      expect(output).to include %{
        <input class="custom-class form--text-field"
          id="user_name" name="user[name]" size="30" title="Name" type="text"
          value="JJ Abrams" />
      }.squish
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
      expect(output).to include %{
        <textarea class="custom-class form--text-area" cols="40" id="user_name" name="user[name]" rows="20" title="Name">
JJ Abrams</textarea>
      }.strip
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
      expect(output).to include %{
        <select class="custom-class form--select"
          id="user_name" name="user[name]"><option value="33">FUN</option></select>
      }.squish
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
      expect(output).to include %{
        <input class="custom-class form--check-box"
          id="user_first_login" name="user[first_login]" title="Name" type="checkbox"
          value="1" />
      }.squish
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
      # no_label=\"true\" is to be removed
      expect(output).to include %{
        <input checked="checked"
               class="form--check-box"
               id="user_enabled_module_names_repositories"
               name="user[enabled_module_names][]"
               no_label=\"true\"
               type="checkbox"
               value="repositories" />
      }.squish
    end
  end

  describe '#radio_button' do
    let(:options) { { title: 'Name' } }

    subject(:output) {
      builder.radio_button :name, 'John'
    }

    it_behaves_like 'not labelled'
    it_behaves_like 'not wrapped in container'
    it_behaves_like 'not wrapped in container', 'radio-button-container'

    it 'should output element' do
      expect(output).to eq %{
        <input id="user_name_john" name="user[name]" type="radio" value="John" />
      }.strip
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
      expect(output).to include %{
        <input class="custom-class form--text-field -number"
          id="user_failed_login_count" name="user[failed_login_count]" title="Bad logins"
          type="number" value="45" />
      }.squish
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
      expect(output).to include %{
        <input class="custom-class form--range-field"
          id="user_failed_login_count" name="user[failed_login_count]" title="Bad logins"
          type="range" value="45" />
      }.squish
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
      expect(output).to include %{
        <input class="custom-class form--search-field" id="user_name"
          name="user[name]" size="30" title="Search name" type="search"
          value="JJ Abrams" />
      }.squish
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
      expect(output).to include %{
        <input class="custom-class form--text-field -email"
          id="user_mail" name="user[mail]" size="30" title="Email" type="email"
          value="jj@lost-mail.com" />
      }.squish
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
      expect(output).to include %{
        <input class="custom-class form--text-field -telephone"
          id="user_mail" name="user[mail]" size="30" title="Not really email"
          type="tel" value="jj@lost-mail.com" />
      }.squish
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
      expect(output).to include %{
        <input class="custom-class form--text-field -password"
          id="user_login" name="user[login]" size="30" title="Not really password"
          type="password" />
      }.squish
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
      expect(output).to include %{
        <input class="custom-class form--file-field"
          id="user_name" name="user[name]" title="Not really file" type="file" />
      }.squish
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
      expect(output).to include %{
        <input class="custom-class form--text-field -url"
          id="user_name" name="user[name]" size="30" title="Not really file"
          type="url" value="JJ Abrams" />
      }.squish
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
      expect(output).to eq %{<input name="commit" type="submit" value="Create User" />}
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
      expect(output).to eq %{<button name="button" type="submit">Create User</button>}
    end
  end
end
