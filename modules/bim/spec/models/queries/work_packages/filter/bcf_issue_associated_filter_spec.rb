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

describe Bim::Queries::WorkPackages::Filter::BcfIssueAssociatedFilter, type: :model do
  include_context 'filter tests'
  let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

  it_behaves_like 'basic query filter' do
    let(:class_key) { :bcf_issue_associated }
    let(:type) { :list }

    describe '#available?' do
      context 'if bim is enabled', with_config: { edition: 'bim' } do
        it 'is available' do
          expect(instance)
            .to be_available
        end
      end

      context 'if bim is disabled' do
        it 'is not available' do
          expect(instance)
            .not_to be_available
        end
      end
    end
  end
end
