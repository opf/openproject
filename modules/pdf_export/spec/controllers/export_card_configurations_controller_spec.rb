#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++


require 'spec_helper'
require File.dirname(__FILE__) + '/../shared_examples'

describe ExportCardConfigurationsController, :type => :controller do
  before do
    allow(@controller).to receive(:require_admin) { true }

    @default_config = FactoryBot.create(:default_export_card_configuration)
    @custom_config = FactoryBot.create(:export_card_configuration)
    @active_config = FactoryBot.create(:active_export_card_configuration)
    @inactive_config = FactoryBot.create(:inactive_export_card_configuration)
    @params = {}
    @valid_rows_yaml = "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
    @invalid_rows_yaml = "group1:\n  invalid_property: true"
    @invalid_property_value_format = "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          font_size: sd\n"
  end

  describe 'Create' do
    context 'with all the values set' do
      it_behaves_like "should let you create a configuration" do
        let(:params) { { :export_card_configuration => { name: "Config 1",
                                                      description: "This is a description",
                                                      rows: @valid_rows_yaml,
                                                      per_page: 5,
                                                      page_size: "A4",
                                                      orientation: "landscape" } } }
      end
    end

    context 'with missing data' do
      it_behaves_like "should not let you create a configuration" do
        let(:params) { { :export_card_configuration => { name: "Config 1" } } }
      end
    end

    context 'with invalid data' do
      it_behaves_like "should not let you create a configuration" do
        let(:params) { { :export_card_configuration => { name: "Config 1",
                                                     rows: @invalid_rows_yaml,
                                                     per_page: 0,
                                                     page_size: "invalid",
                                                     orientation: "invalid" } } }
      end
    end

    context 'with invalid data format' do
      it_behaves_like "should not let you create a configuration" do
        let(:params) { { :export_card_configuration => { name: "Config 1",
                                                     rows: @invalid_property_value_format,
                                                     per_page: 1,
                                                     page_size: "A4",
                                                     orientation: "landscape" } } }
      end
    end
  end

  describe 'Update' do
    it 'should let you update a configuration' do
      @params[:id] = @custom_config.id
      @params[:export_card_configuration] = { per_page: 4 }
      put 'update', params: @params

      expect(response).to redirect_to :action => 'index'
      expect(flash[:notice]).to eql(I18n.t(:notice_successful_update))
    end

    it 'should not let you update a configuration with invalid per_page' do
      @params[:id] = @custom_config.id
      @params[:export_card_configuration] = { per_page: 0 }
      put 'update', params: @params

      expect(response).to render_template('edit')
    end

    it 'should not let you update a configuration with invalid page_size' do
      @params[:id] = @custom_config.id
      @params[:export_card_configuration] = { page_size: "invalid"}
      put 'update', params: @params

      expect(response).to render_template('edit')
    end

    it 'should not let you update a configuration with invalid orientation' do
      @params[:id] = @custom_config.id
      @params[:export_card_configuration] = { orientation: "invalid" }
      put 'update', params: @params

      expect(response).to render_template('edit')
    end

    it 'should not let you update a configuration with invalid rows yaml' do
      @params[:id] = @custom_config.id
      @params[:export_card_configuration] = { rows: "asdf ',#\""}
      put 'update', params: @params

      expect(response).to render_template('edit')
    end
  end

  describe 'Delete' do
    it 'should let you delete a custom configuration' do
      @params[:id] = @custom_config.id
      delete 'destroy', params: @params

      expect(response).to redirect_to :action => 'index'
      expect(flash[:notice]).to eql(I18n.t(:notice_successful_delete))
    end

    it 'should not let you delete the default configuration' do
      @params[:id] = @default_config.id
      delete 'destroy', params: @params

      expect(response).to redirect_to :action => 'index'
      expect(flash[:notice]).to eql(I18n.t(:error_can_not_delete_export_card_configuration))
    end
  end

  describe 'Activate' do
    it 'should let you activate an inactive configuration' do
      @params[:id] = @inactive_config.id
      post 'activate', params: @params

      expect(response).to redirect_to :action => 'index'
      expect(flash[:notice]).to eql(I18n.t(:notice_export_card_configuration_activated))
    end
  end

  describe "Deactivate" do
    it 'should let you de-activate an active configuration' do
      @params[:id] = @active_config.id
      post 'deactivate', params: @params

      expect(response).to redirect_to :action => 'index'
      expect(flash[:notice]).to eql(I18n.t(:notice_export_card_configuration_deactivated))
    end

    it 'should not let you de-activate the default configuration' do
      @params[:id] = @default_config.id
      post 'deactivate', params: @params

      expect(response).to redirect_to :action => 'index'
      expect(flash[:notice]).to eql(I18n.t(:error_can_not_deactivate_export_card_configuration))
    end
  end
end
