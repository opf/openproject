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
require_relative 'shared_query_column_specs'

describe Queries::WorkPackages::Columns::PropertyColumn, type: :model do
  let(:instance) { described_class.new(:query_column) }

  it_behaves_like 'query column'

  describe 'instances' do
    context 'done_ratio disabled' do
      it 'the done ratio column does not exist' do
        allow(WorkPackage)
          .to receive(:done_ratio_disabled?)
          .and_return(true)

        expect(described_class.instances.map(&:name)).not_to include :done_ratio
      end
    end

    context 'done_ratio enabled' do
      it 'the done ratio column exists' do
        allow(WorkPackage)
          .to receive(:done_ratio_disabled?)
          .and_return(false)

        expect(described_class.instances.map(&:name)).to include :done_ratio
      end
    end
  end
end
