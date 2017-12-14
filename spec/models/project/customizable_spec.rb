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

describe Project, 'customizable', type: :model do
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:stub_available_custom_fields) do
    custom_fields_stub = double('custom fields stub')
    allow(CustomField)
      .to receive(:where)
      .with(type: "ProjectCustomField")
      .and_return(custom_fields_stub)

    allow(custom_fields_stub)
      .to receive(:order)
      .with(:position)
      .and_return(available_custom_fields)
  end

  before do
    stub_available_custom_fields
  end

  describe 'custom_value_for' do
    subject { project.custom_value_for(custom_field) }

    context 'for a boolean custom field' do
      let(:custom_field) { FactoryGirl.build_stubbed(:bool_project_custom_field) }
      let(:available_custom_fields) { [custom_field] }

      context 'with no value set' do
        it 'returns a custom value' do
          expect(subject)
            .to be_present
        end

        it 'is unpersisted' do
          expect(subject)
            .to be_new_record
        end

        it 'has nil as its value' do
          expect(subject.value)
            .to be_nil
        end
      end

      context 'with a value set' do
        let(:custom_value) do
          FactoryGirl.build_stubbed(:custom_value,
                                    custom_field: custom_field,
                                    value: true)
        end
        before do
          allow(project)
            .to receive(:custom_values)
            .and_return([custom_value])
        end

        it 'returns the custom value' do
          expect(subject)
            .to eql custom_value
        end
      end
    end
  end
end
