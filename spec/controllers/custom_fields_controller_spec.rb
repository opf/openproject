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

describe CustomFieldsController, type: :controller do
  let(:custom_field) { FactoryGirl.build(:custom_field) }
  let(:available_languages) { ['de', 'en'] }

  before do
    allow(@controller).to receive(:authorize)
    allow(@controller).to receive(:check_if_login_required)
    allow(@controller).to receive(:require_admin)
  end

  describe 'POST edit' do
    before do
      allow(Setting).to receive(:available_languages).and_return(available_languages)
      allow(CustomField).to receive(:find).and_return(custom_field)
    end

    describe 'WITH all ok params' do
      let(:de_name) { 'Ticket Feld' }
      let(:en_name) { 'Issue Field' }
      let(:params) {
        { 'custom_field' => { 'translations_attributes' => { '0' => { 'name' => de_name, 'locale' => 'de' },
                                                             '1' => { 'name' => en_name, 'locale' => 'en' } } } }
      }

      before do
        put :update, params
      end

      it { expect(response).to be_redirect }
      it { expect(custom_field.name(:de)).to eq(de_name) }
      it { expect(custom_field.name(:en)).to eq(en_name) }
    end

    describe 'WITH one empty name params' do
      let(:en_name) { 'Issue Field' }
      let(:de_name) { '' }
      let(:params) {
        { 'custom_field' => { 'translations_attributes' => { '0' => { 'name' => de_name, 'locale' => 'de' },
                                                             '1' => { 'name' => en_name, 'locale' => 'en' } } } }
      }

      before do
        put :update, params
      end

      it { expect(response).to be_redirect }
      it { expect(custom_field.name(:de)).to eq(en_name) }
      it { expect(custom_field.name(:en)).to eq(en_name) }
    end

  end

  describe 'POST new' do
    before do
      allow(Setting).to receive(:available_languages).and_return(available_languages)
    end

    describe 'WITH empty name param' do
      let(:en_name) { '' }
      let(:de_name) { '' }
      let(:params) {
        { 'type' => 'WorkPackageCustomField',
          'custom_field' => { 'translations_attributes' => { '0' => { 'name' => de_name, 'locale' => 'de' },
                                                             '1' => { 'name' => en_name, 'locale' => 'en' } },
                              'field_format' => 'string' } }
      }
      before do
        post :create, params
      end

      it { expect(response).to render_template 'new' }
      it { expect(assigns(:custom_field).errors.messages[:name].first).to eq "can't be blank" }
      it { expect(assigns(:custom_field).translations).to be_empty }
    end

    describe 'WITH all ok params' do
      let(:de_name) { 'Ticket Feld' }
      let(:en_name) { 'Issue Field' }
      let(:params) {
        { 'type' => 'WorkPackageCustomField',
          'custom_field' => { 'translations_attributes' => { '0' => { 'name' => de_name, 'locale' => 'de' },
                                                             '1' => { 'name' => en_name, 'locale' => 'en' } },
                              'field_format' => 'string' } }
      }

      before do
        post :create, params
      end

      it { expect(response.status).to eql(302) }
      it { expect(assigns(:custom_field).translations.find { |elem| elem.locale == :de }[:name]).to eq(de_name) }
      it { expect(assigns(:custom_field).translations.find { |elem| elem.locale == :en }[:name]).to eq(en_name) }
    end

    describe 'WITH one empty name params' do
      let(:en_name) { 'Issue Field' }
      let(:de_name) { '' }
      let(:params) {
        { 'type' => 'WorkPackageCustomField',
          'custom_field' => { 'translations_attributes' => { '0' => { 'name' => de_name, 'locale' => 'de' },
                                                             '1' => { 'name' => en_name, 'locale' => 'en' } },
                              'field_format' => 'string' } }
      }
      before do
        post :create, params
      end

      it { expect(response.status).to eql(302) }
      it { expect(assigns(:custom_field).translations.find { |elem| elem.locale == :de }).to be_nil }
      it { expect(assigns(:custom_field).translations.find { |elem| elem.locale == :en }[:name]).to eq(en_name) }
    end

    describe 'WITH different language and default_value params' do
      let(:en_name) { 'Issue Field' }
      let(:en_default) { 'EN Default Value' }
      let(:de_name) { '' }
      let(:de_default) { 'DE Default Value' }
      let(:params) {
        { 'type' => 'WorkPackageCustomField',
          'custom_field' => { 'translations_attributes' =>
                                           { '0' => { 'name' => de_name, 'locale' => 'de', 'default_value' => de_default },
                                             '1' => { 'name' => en_name, 'locale' => 'en', 'default_value' => '' } },
                              'field_format' => 'string' } }
      }
      before do
        post :create, params
      end

      it { expect(response.status).to eql(302) }
      it { expect(assigns(:custom_field).translations.find { |elem| elem.locale == :de }[:name]).to eq(en_name) }
      it { expect(assigns(:custom_field).translations.find { |elem| elem.locale == :en }[:name]).to eq(en_name) }
      it { expect(assigns(:custom_field).translations.find { |elem| elem.locale == :en }[:default_value]).to be_nil }
      it { expect(assigns(:custom_field).translations.find { |elem| elem.locale == :de }[:default_value]).to eq(de_default) }
    end
  end
end
