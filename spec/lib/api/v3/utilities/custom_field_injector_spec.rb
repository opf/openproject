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

describe ::API::V3::Utilities::CustomFieldInjector do
  let(:custom_field) {
    FactoryGirl.build(:custom_field,
                      field_format: 'bool')
  }

  describe 'TYPE_MAP' do
    it 'supports all available formats' do
      Redmine::CustomFieldFormat.available_formats.each do |format|
        expect(described_class::TYPE_MAP[format]).to_not be_nil
      end
    end
  end

  describe ':inject_schema' do
    let(:schema_class) { Class.new(::API::Decorators::Schema) }
    let(:rendered_json) { schema_class.new(nil).to_json }
    let(:cf_path) { "customField#{custom_field.id}" }
    subject { described_class.new(schema_class) }

    before do
      subject.inject_schema(custom_field)
    end

    it 'injects the schema' do
      expect(rendered_json).to have_json_path(cf_path)
    end

    it 'sets the type' do
      expect(rendered_json).to be_json_eql('Boolean'.to_json).at_path("#{cf_path}/type")
    end

    it 'sets the name' do
      expect(rendered_json).to be_json_eql(custom_field.name.to_json).at_path("#{cf_path}/name")
    end

    it 'marks the field as writable' do
      expect(rendered_json).to be_json_eql(true.to_json).at_path("#{cf_path}/writable")
    end

    context 'when the custom field is required' do
      let(:custom_field) { FactoryGirl.build(:custom_field, is_required: true) }

      it 'marks the field as required' do
        expect(rendered_json).to be_json_eql(true.to_json).at_path("#{cf_path}/required")
      end
    end

    context 'when the custom field is not required' do
      let(:custom_field) { FactoryGirl.build(:custom_field, is_required: false) }

      it 'marks the field as required' do
        expect(rendered_json).to be_json_eql(false.to_json).at_path("#{cf_path}/required")
      end
    end
  end
end
