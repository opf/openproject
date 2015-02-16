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
                      field_format: 'bool',
                      is_required: true)
  }

  describe 'TYPE_MAP' do
    it 'supports all available formats' do
      Redmine::CustomFieldFormat.available_formats.each do |format|
        expect(described_class::TYPE_MAP[format]).to_not be_nil
      end
    end
  end

  describe ':inject_schema' do
    let(:modified_class) { Class.new(::API::Decorators::Schema) }
    let(:cf_path) { "customField#{custom_field.id}" }
    let(:injector) { described_class.new(modified_class) }
    subject { modified_class.new(nil).to_json }

    before do
      injector.inject_schema(custom_field)
    end

    describe 'basic custom field' do
      it_behaves_like 'has basic schema properties' do
        let(:path) { cf_path }
        let(:type) { 'Boolean' }
        let(:name) { custom_field.name }
        let(:required) { true }
        let(:writable) { true }
      end

      context 'when the custom field is not required' do
        let(:custom_field) { FactoryGirl.build(:custom_field, is_required: false) }

        it 'marks the field as not required' do
          is_expected.to be_json_eql(false.to_json).at_path("#{cf_path}/required")
        end
      end
    end
  end
end
