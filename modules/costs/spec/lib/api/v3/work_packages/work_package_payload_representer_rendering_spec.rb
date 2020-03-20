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

describe ::API::V3::WorkPackages::WorkPackagePayloadRepresenter, 'rendering' do
  include API::V3::Utilities::PathHelper

  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             start_date: Date.today.to_datetime,
                             due_date: Date.today.to_datetime,
                             created_at: DateTime.now,
                             updated_at: DateTime.now,
                             cost_object: cost_object,
                             type: FactoryBot.build_stubbed(:type)) do |wp|
    end
  end

  let(:cost_object) { FactoryBot.build_stubbed(:cost_object) }

  let(:permissions) { %i(view_cost_objects edit_work_packages) }

  let(:project) { work_package.project }

  include_context 'user with stubbed permissions'

  let(:representer) do
    ::API::V3::WorkPackages::WorkPackagePayloadRepresenter
      .create(work_package, current_user: user)
  end

  subject(:generated) { representer.to_json }

  describe '_links' do
    describe 'costObject' do
      context 'without a cost object assigned' do
        let(:cost_object) { nil }

        it 'has an empty href' do
          expect(subject)
            .to be_json_eql(nil.to_json)
            .at_path '_links/costObject/href'
        end
      end

      context 'with a cost object assigned' do
        it 'has an href to the cost object' do
          expect(subject)
            .to be_json_eql(api_v3_paths.budget(cost_object.id).to_json)
            .at_path '_links/costObject/href'
        end
      end

      context 'without necessary permissions' do
        let(:permissions) { %i(edit_work_packages) }

        it 'has no href' do
          expect(subject)
            .not_to have_json_path('_links/costObject')
        end
      end
    end
  end
end
