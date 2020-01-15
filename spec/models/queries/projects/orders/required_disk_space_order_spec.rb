#-- encoding: UTF-8

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

describe Queries::Projects::Orders::RequiredDiskSpaceOrder, type: :model do
  let(:instance) do
    described_class.new('').tap do |i|
      i.direction = direction
    end
  end
  let(:direction) { :asc }

  describe '#scope' do
    context 'with a valid direction' do
      it 'orders by the disk space' do
        expect(instance.scope.to_sql)
          .to eql(Project.order(Arel.sql(Project.required_disk_space_sum).asc).to_sql)
      end
    end

    context 'with an invalid direction' do
      let(:direction) { 'bogus' }

      it 'raises an error' do
        expect { instance.scope }
          .to raise_error(ArgumentError)
      end
    end
  end
end
