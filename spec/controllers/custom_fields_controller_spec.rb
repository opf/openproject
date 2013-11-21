#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe CustomFieldsController do
  let(:custom_field) { FactoryGirl.build(:custom_field) }

  before do
    @controller.stub(:authorize)
    @controller.stub(:check_if_login_required)
    @controller.stub(:require_admin)
  end

  describe "POST edit" do
    before do
      Setting.available_languages = ["de", "en"]
      CustomField.stub(:find).and_return(custom_field)
    end

    describe "WITH all ok params" do
      let(:de_name) { "Ticket Feld" }
      let(:en_name) { "Issue Field" }
      let(:params) { { "custom_field" => { "translations_attributes" => { "0" => { "name" => de_name, "locale" => "de" }, "1" => { "name" => en_name, "locale" => "en" } } } } }

      before do
        put :edit, params
      end

      it { response.should be_redirect }
      it { custom_field.name(:de).should == de_name }
      it { custom_field.name(:en).should == en_name }
    end

    describe "WITH one empty name params" do
      let(:en_name) { "Issue Field" }
      let(:de_name) { "" }
      let(:params) { { "custom_field" => { "translations_attributes" => { "0" => { "name" => de_name, "locale" => "de" }, "1" => { "name" => en_name, "locale" => "en" } } } } }

      before do
        put :edit, params
      end

      it { response.should be_redirect }
      it { custom_field.name(:de).should == en_name }
      it { custom_field.name(:en).should == en_name }
    end
  end

  describe "POST new" do
    before do
      Setting.available_languages = ["de", "en"]
    end

    describe "WITH all ok params" do
      let(:de_name) { "Ticket Feld" }
      let(:en_name) { "Issue Field" }
      let(:params) { { "type" => "WorkPackageCustomField",
                       "custom_field" => { "translations_attributes" => { "0" => { "name" => de_name, "locale" => "de" }, "1" => { "name" => en_name, "locale" => "en" } } } } }

      before do
        post :new, params
      end

      it { response.should be_success }
      it { assigns(:custom_field).name(:de).should == de_name }
      it { assigns(:custom_field).name(:en).should == en_name }
    end

    describe "WITH one empty name params" do
      let(:en_name) { "Issue Field" }
      let(:de_name) { "" }
      let(:params) { { "type" => "WorkPackageCustomField",
                       "custom_field" => { "translations_attributes" => { "0" => { "name" => de_name, "locale" => "de" }, "1" => { "name" => en_name, "locale" => "en" } } } } }

      before do
        post :new, params
      end

      it { response.should be_success }
      it { assigns(:custom_field).name(:de).should == en_name }
      it { assigns(:custom_field).name(:en).should == en_name }
    end
  end
end
