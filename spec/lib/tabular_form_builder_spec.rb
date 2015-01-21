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
  let(:resource) { FactoryGirl.build(:user) }
  let(:builder)  { TabularFormBuilder.new(:user, resource, helper, {}, nil) }

  shared_examples_for 'labelled' do
    it { is_expected.to have_selector 'label' }
  end

  shared_examples_for 'not labelled' do
    it { is_expected.not_to have_selector 'label' }
  end

  shared_examples_for 'labelled by default' do
    context 'by default' do
      it_behaves_like 'labelled'
    end

    context 'with no_label option' do
      let(:options) { { no_label: true } }

      it_behaves_like 'not labelled'
    end
  end

  describe '#text_field' do
    let(:options) { { title: 'Name' } }

    subject(:output) {
      builder.text_field :name, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="text"]'
    end
  end

  describe '#text_area' do
    let(:options) { { title: 'Name' } }

    subject(:output) {
      builder.text_area :name, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'textarea'
    end
  end

  describe '#select' do
    let(:options) { { title: 'Name' } }

    subject(:output) {
      builder.select :name, '<option value="33">FUN</option>'.html_safe, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'select'
      expect(output).to have_selector 'option[value="33"]'
      expect(output).to have_text 'FUN'
    end
  end

  describe '#collection_select' do
    let(:options) { { title: 'Name' } }

    subject(:output) {
      builder.collection_select :name, [
        OpenStruct.new(id: 56, name: 'Diana'),
        OpenStruct.new(id: 46, name: 'Ricky'),
        OpenStruct.new(id: 33, name: 'Jonas')
      ], :id, :name, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'select > option', count: 3
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

    it 'should output element' do
      expect(output).to have_selector 'select', count: 3
      expect(output).to have_selector 'select:nth-of-type(2) > option', count: 12
      expect(output).to have_selector 'select:last > option', count: 31
    end
  end

  describe '#check_box' do
    let(:options) { { title: 'Name' } }

    subject(:output) {
      builder.check_box :first_login, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="checkbox"]'
    end
  end

  describe '#radio_button' do
    let(:options) { { title: 'Name' } }

    subject(:output) {
      builder.radio_button :name, 'John'
    }

    it_behaves_like 'not labelled'

    it 'should output element' do
      expect(output).to have_selector 'input[type="radio"]'
    end
  end

  describe '#number_field' do
    let(:options) { { title: 'Bad logins' } }

    subject(:output) {
      builder.number_field :failed_login_count, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="number"]'
    end
  end

  describe '#range_field' do
    let(:options) { { title: 'Bad logins' } }

    subject(:output) {
      builder.range_field :failed_login_count, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="range"]'
    end
  end

  describe '#search_field' do
    let(:options) { { title: 'Search name' } }

    subject(:output) {
      builder.search_field :name, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="search"]'
    end
  end

  describe '#email_field' do
    let(:options) { { title: 'Email' } }

    subject(:output) {
      builder.email_field :mail, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="email"]'
    end
  end

  describe '#telephone_field' do
    let(:options) { { title: 'Not really email' } }

    subject(:output) {
      builder.telephone_field :mail, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="tel"]'
    end
  end

  describe '#password_field' do
    let(:options) { { title: 'Not really password' } }

    subject(:output) {
      builder.password_field :login, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="password"]'
    end
  end

  describe '#file_field' do
    let(:options) { { title: 'Not really file' } }

    subject(:output) {
      builder.file_field :name, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="file"]'
    end
  end

  describe '#url_field' do
    let(:options) { { title: 'Not really file' } }

    subject(:output) {
      builder.url_field :name, options
    }

    it_behaves_like 'labelled by default'

    it 'should output element' do
      expect(output).to have_selector 'input[type="url"]'
    end
  end

  describe '#submit' do
    subject(:output) {
      builder.submit
    }

    it_behaves_like 'not labelled'

    it 'should output element' do
      expect(output).to have_selector 'input[type="submit"]'
    end
  end

  describe '#button' do
    subject(:output) {
      builder.button
    }

    it_behaves_like 'not labelled'

    it 'should output element' do
      expect(output).to have_selector 'button'
    end
  end
end
