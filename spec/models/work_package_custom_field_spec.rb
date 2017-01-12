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

describe WorkPackageCustomField, type: :model do
  describe '.summable' do
    let (:custom_field) {
      FactoryGirl.create(:work_package_custom_field,
                         name: 'Database',
                         field_format: 'list',
                         possible_values: ['MySQL', 'PostgreSQL', 'Oracle'],
                         is_required: true)
    }

    before do
      custom_field.save!
    end

    context 'with a summable field' do
      before do
        allow(Setting)
          .to receive(:work_package_list_summable_columns)
          .and_return(["cf_#{custom_field.id}"])
      end

      it 'contains the custom_field' do
        expect(described_class.summable)
          .to match_array [custom_field]
      end
    end

    context 'without a summable field' do
      before do
        allow(Setting)
          .to receive(:work_package_list_summable_columns)
          .and_return(['blubs'])
      end

      it 'does not contain the custom_field' do
        expect(described_class.summable)
          .to be_empty
      end
    end
  end
end
