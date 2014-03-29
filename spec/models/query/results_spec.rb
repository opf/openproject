#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe ::Query::Results do
  let(:query) { FactoryGirl.build :query }
  let(:query_results) do
    ::Query::Results.new query, include: [:assigned_to, :type, :priority, :category, :fixed_version],
                                order: "work_packages.root_id DESC, work_packages.lft ASC"
  end

  describe '#work_package_count_by_group' do
    context 'when grouping by responsible' do
      before { query.group_by = 'responsible' }

      it 'should produce a valid SQL statement' do
        expect { query_results.work_package_count_by_group }.not_to raise_error
      end
    end
  end
end
