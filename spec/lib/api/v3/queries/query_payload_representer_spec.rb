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

describe ::API::V3::Queries::QueryPayloadRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:query) { FactoryGirl.build_stubbed(:query, project: project) }
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:user) { double('current_user') }
  let(:representer) do
    described_class.new(query, current_user: user)
  end

  subject { representer.to_json }

  describe 'generation' do
    context 'properties' do
      context 'showHierarchies' do
        it 'is true if query.show_hierarchies is true' do
          query.show_hierarchies = true

          is_expected.to be_json_eql(true.to_json).at_path('showHierarchies')
        end

        it 'is false if query.show_hierarchies is false' do
          query.show_hierarchies = false

          is_expected.to be_json_eql(false.to_json).at_path('showHierarchies')
        end
      end
    end
  end
end
