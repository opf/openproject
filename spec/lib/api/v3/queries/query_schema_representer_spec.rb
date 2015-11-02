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

describe ::API::V3::Queries::Schema::QuerySchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) { FactoryGirl.build(:user) }
  let(:schema) { ::API::V3::Queries::Schema::SpecificQuerySchema.new }
  let(:self_link) { '/a/self/link' }
  let(:representer) {
    described_class.new(schema,
                        self_link: self_link,
                        current_user: current_user)
  }
  subject { representer.to_json }

  describe 'self link' do
    it_behaves_like 'has an untitled link' do
      let(:link) { 'self' }
      let(:href) { self_link }
    end
  end

  describe '_type' do
    it 'is indicated as Schema' do
      is_expected.to be_json_eql('Schema'.to_json).at_path('_type')
    end
  end

  describe 'id' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'id' }
      let(:type) { 'Integer' }
      let(:name) { I18n.t('attributes.id') }
      let(:required) { true }
      let(:writable) { false }
    end
  end

  describe 'name' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'name' }
      let(:type) { 'String' }
      let(:name) { I18n.t('attributes.name') }
      let(:required) { true }
      let(:writable) { true }
    end

    it 'indicates its minimum length' do
      is_expected.to be_json_eql(1.to_json).at_path('name/minLength')
    end

    it 'indicates its maximum length' do
      is_expected.to be_json_eql(255.to_json).at_path('name/maxLength')
    end
  end

  describe 'filters' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'filters' }
      let(:type) { 'Object' }
      let(:name) { I18n.t('activerecord.attributes.query.filters') }
      let(:required) { true }
      let(:writable) { true }
    end
  end

  describe 'columnNames' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'columnNames' }
      let(:type) { 'String[]' }
      let(:name) { I18n.t('activerecord.attributes.query.column_names') }
      let(:required) { true }
      let(:writable) { true }
    end
  end

  describe 'sortCriteria' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'sortCriteria' }
      let(:type) { 'Object' }
      let(:name) { I18n.t('activerecord.attributes.query.sort_criteria') }
      let(:required) { true }
      let(:writable) { true }
    end
  end

  describe 'groupBy' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'groupBy' }
      let(:type) { 'String' }
      let(:name) { I18n.t('activerecord.attributes.query.group_by') }
      let(:required) { false }
      let(:writable) { true }
    end
  end

  describe 'displaySums' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'displaySums' }
      let(:type) { 'Boolean' }
      let(:name) { I18n.t('attributes.display_sums') }
      let(:required) { true }
      let(:writable) { true }
    end
  end

  describe 'isPublic' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'isPublic' }
      let(:type) { 'Boolean' }
      let(:name) { I18n.t('attributes.is_public') }
      let(:required) { true }
      let(:writable) { false }
    end
  end

  describe 'isStarred' do
    it_behaves_like 'has basic schema properties' do
      let(:path) { 'isStarred' }
      let(:type) { 'Boolean' }
      let(:name) { I18n.t('attributes.is_starred') }
      let(:required) { true }
      let(:writable) { false }
    end
  end
end
