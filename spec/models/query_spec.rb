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

describe Query, type: :model do
  let(:query) { FactoryGirl.build(:query) }

  describe 'available_columns' do
    context 'with work_package_done_ratio NOT disabled' do
      it 'should include the done_ratio column' do
        expect(query.available_columns.find { |column| column.name == :done_ratio }).to be_truthy
      end
    end

    context 'with work_package_done_ratio disabled' do
      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return('disabled')
      end

      it 'should NOT include the done_ratio column' do
        expect(query.available_columns.find { |column| column.name == :done_ratio }).to be_nil
      end
    end

  end

  describe '#valid?' do
    it 'should not be valid without a name' do
      query.name = ''
      expect(query.save).to be_falsey
      expect(query.errors[:name].first).to include(I18n.t('activerecord.errors.messages.blank'))
    end

    context 'with a missing value and an operator that requires values' do
      before do
        query.add_filter('due_date', 't-', [''])
      end

      it 'is not valid and creates an error' do
        expect(query.valid?).to be_falsey
        expect(query.errors[:base].first).to include(I18n.t('activerecord.errors.messages.blank'))
      end
    end

    context 'when filters are blank' do
      let(:status) { FactoryGirl.create :status }
      let(:query) { FactoryGirl.build(:query).tap { |q| q.filters = [] } }

      it 'is valid' do
        expect(query.valid?).to be_truthy
      end
    end

    context 'with a missing value for a custom field' do
      let(:custom_field) { FactoryGirl.create :text_issue_custom_field }
      let(:query) { FactoryGirl.build(:query) }

      before do
        query.filters = [Queries::WorkPackages::Filter.new('cf_' + custom_field.id.to_s, operator: '=', values: [''])]
      end

      it 'should have the name of the custom field in the error message' do
        expect(query.valid?).to be_falsey
        expect(query.errors.messages[:base].to_s).to include(custom_field.name)
      end
    end
  end

end
