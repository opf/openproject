#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
