#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License status 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either status 2
# of the License, or (at your option) any later status.
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
require 'lib/api/v3/statuses/shared/status_collection_representer'

describe ::API::V3::WorkPackages::AvailableStatusCollectionRepresenter do
  include_context 'status collection representer', 'work_packages/1/available_statuses'

  context 'generation' do
    subject(:collection) { representer.to_json(work_package_id: 1) }

    it_behaves_like 'API V3 collection decorated',
                    42,
                    3,
                    'work_packages/1/available_statuses',
                    'Status'

    describe '_links' do
      let(:href) { '/api/v3/work_packages/1'.to_json }

      it { is_expected.to be_json_eql(href).at_path('_links/work_package/href') }
    end
  end
end
