#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe CustomFieldFormBuilder do
  include Capybara::RSpecMatchers

  let(:helper)   { ActionView::Base.new }
  let(:resource) {
    FactoryGirl.build(:user,
                      firstname:  'JJ',
                      lastname:   'Abrams',
                      login:      'lost',
                      mail:       'jj@lost-mail.com',
                      failed_login_count: 45)
  }
  let(:builder)  { described_class.new(:user, resource, helper, {}) }

  describe '#custom_field' do
    let(:options) { { class: 'custom-class' } }

    let(:resource) {
      FactoryGirl.build_stubbed(:custom_value)
    }

    subject(:output) {
      builder.custom_field options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default' do
      let(:container_count) { 2 }
    end

    context 'for a bool custom field' do
      it_behaves_like 'wrapped in container', 'check-box-container' do
        let(:container_count) { 2 }
      end

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <input class="custom-class form--check-box"
                 id="user#{resource.custom_field_id}"
                 lang=\"en\"
                 name="user[#{resource.custom_field_id}]"
                 type="checkbox"
                 value="1" />
        }).at_path('input:nth-of-type(2)')
      end
    end

    context 'for a date custom field' do
      before do
        expect(helper)
          .to receive(:calendar_for)
          .with("user#{resource.custom_field_id}")

        resource.custom_field.field_format = 'date'
      end

      it_behaves_like 'wrapped in container', 'text-field-container' do
        let(:container_count) { 2 }
      end

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <input class="custom-class form--text-field"
                 id="user#{resource.custom_field_id}"
                 lang=\"en\"
                 name="user[#{resource.custom_field_id}]"
                 type="text" />
        }).at_path('input')
      end
    end

    context 'for a text custom field' do
      before do
        resource.custom_field.field_format = 'text'
      end

      it_behaves_like 'wrapped in container', 'text-area-container' do
        let(:container_count) { 2 }
      end

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <textarea class="custom-class form--text-area"
                    id="user#{resource.custom_field_id}"
                    lang=\"en\"
                    name="user[#{resource.custom_field_id}]"
                    rows="3">
          </textarea>
        }).at_path('textarea')
      end
    end

    context 'for a string custom field' do
      before do
        resource.custom_field.field_format = 'string'
      end

      it_behaves_like 'wrapped in container', 'text-field-container' do
        let(:container_count) { 2 }
      end

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <input class="custom-class form--text-field"
                 id="user#{resource.custom_field_id}"
                 lang=\"en\"
                 name="user[#{resource.custom_field_id}]"
                 type="text" />
        }).at_path('input')
      end
    end

    context 'for an int custom field' do
      before do
        resource.custom_field.field_format = 'int'
      end

      it_behaves_like 'wrapped in container', 'text-field-container' do
        let(:container_count) { 2 }
      end

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <input class="custom-class form--text-field"
                 id="user#{resource.custom_field_id}"
                 lang=\"en\"
                 name="user[#{resource.custom_field_id}]"
                 type="text" />
        }).at_path('input')
      end
    end

    context 'for a float custom field' do
      before do
        resource.custom_field.field_format = 'float'
      end

      it_behaves_like 'wrapped in container', 'text-field-container' do
        let(:container_count) { 2 }
      end

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <input class="custom-class form--text-field"
                 id="user#{resource.custom_field_id}"
                 lang=\"en\"
                 name="user[#{resource.custom_field_id}]"
                 type="text" />
        }).at_path('input')
      end
    end

    context 'for a list custom field' do
      before do
        custom_field = resource.custom_field

        custom_field.field_format = 'list'
        custom_field.save!

        custom_field.custom_options.create! value: 'my_option', position: 1
      end

      it_behaves_like 'wrapped in container', 'select-container'

      it 'should output element' do
        value = resource.custom_field.custom_options.first.id

        expect(output).to be_html_eql(%{
          <select class="custom-class form--select"
                  id="user#{resource.custom_field_id}"
                  lang=\"en\"
                  name="user[#{resource.custom_field_id}]"
                  no_label="true"><option
                  value=\"\"></option>
                  <option value=\"#{value}\">my_option</option></select>
        }).at_path('select')
      end

      context 'which is required and has no default value' do
        before do
          resource.custom_field.is_required = true
        end

        it 'should output element' do
          value = resource.custom_field.custom_options.first.id

          expect(output).to be_html_eql(%{
            <select class="custom-class form--select"
                    id="user#{resource.custom_field_id}"
                    lang=\"en\"
                    name="user[#{resource.custom_field_id}]"
                    no_label="true"><option value=\"\">---
                    Please select ---</option>
                    <option value=\"#{value}\">my_option</option></select>
          }).at_path('select')
        end
      end

      context 'which is required and a default value' do
        before do
          resource.custom_field.is_required = true
          resource.custom_field.custom_options.first.update default_value: true
        end

        it 'should output element' do
          value = resource.custom_field.custom_options.first.id

          expect(output).to be_html_eql(%{
            <select class="custom-class form--select"
                    id="user#{resource.custom_field_id}"
                    lang=\"en\"
                    name="user[#{resource.custom_field_id}]"
                    no_label="true"><option
                    value=\"#{value}\">my_option</option></select>
          }).at_path('select')
        end
      end
    end

    context 'for a user custom field' do
      before do
        resource.custom_field.field_format = 'user'
      end

      it_behaves_like 'wrapped in container', 'select-container'

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <select class="custom-class form--select"
                  id="user#{resource.custom_field_id}"
                  lang=\"en\"
                  name="user[#{resource.custom_field_id}]"
                  no_label="true"><option value=\"\"></option>
          </select>
        }).at_path('select')
      end

      context 'which is required and has no default value' do
        before do
          resource.custom_field.is_required = true
        end

        it 'should output element' do
          expect(output).to be_html_eql(%{
            <select class="custom-class form--select"
                    id="user#{resource.custom_field_id}"
                    lang=\"en\"
                    name="user[#{resource.custom_field_id}]"
                    no_label="true"><option value=\"\">---
                    Please select ---</option>
            </select>
          }).at_path('select')
        end
      end
    end

    context 'for a version custom field' do
      before do
        resource.custom_field.field_format = 'version'
      end

      it_behaves_like 'wrapped in container', 'select-container'

      it 'should output element' do
        expect(output).to be_html_eql(%{
          <select class="custom-class form--select"
                  id="user#{resource.custom_field_id}"
                  lang=\"en\"
                  name="user[#{resource.custom_field_id}]"
                  no_label="true"><option value=\"\"></option>
          </select>
        }).at_path('select')
      end

      context 'which is required and has no default value' do
        before do
          resource.custom_field.is_required = true
        end

        it 'should output element' do
          expect(output).to be_html_eql(%{
            <select class="custom-class form--select"
                    id="user#{resource.custom_field_id}"
                    lang=\"en\"
                    name="user[#{resource.custom_field_id}]"
                    no_label="true"><option value=\"\">---
                    Please select ---</option>
            </select>
          }).at_path('select')
        end
      end
    end
  end
end
