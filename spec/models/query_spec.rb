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

describe Query do
  let(:query) { FactoryGirl.build(:query) }

  describe 'available_columns' do
    context 'with work_package_done_ratio NOT disabled' do
      it 'should include the done_ratio column' do
        query.available_columns.find {|column| column.name == :done_ratio}.should be_true
      end
    end

    context 'with work_package_done_ratio disabled' do
      before do
        Setting.stub(:work_package_done_ratio).and_return('disabled')
      end

      it 'should NOT include the done_ratio column' do
        query.available_columns.find {|column| column.name == :done_ratio}.should be_nil
      end
    end

  end

  describe '#valid?' do
    context 'with a missing value' do
      before do
        query.add_filter('due_date', 't-', [''])
      end

      it 'should not be valid and create an error' do
        expect(query.valid?).to be_false

        expect(query.errors[:base].first).to include(I18n.t('activerecord.errors.messages.invalid'))
      end
    end
  end

end
