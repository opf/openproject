#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe Calendar::ResolveWorkPackagesService, type: :model do
  let(:user_1) do
    create(:user,
           member_in_project: project,
           member_with_permissions: permissions)
  end
  let(:user_2_without_permission) do
    create(:user,
           member_in_project: project,
           member_with_permissions: [])
  end
  let(:user_3_not_member) do
    create(:user,
           member_in_project: nil)
  end
  let(:permissions) { %i[view_work_packages] }
  let(:project) { create(:project, work_packages: [work_package_1]) }
  let(:work_package_1) { create(:work_package) }
  let(:query) do
    create(:query,
           project: project,
           user: user_1,
           public: false)
  end
  
  let(:instance) do
    described_class.new()
  end

  context 'resolves work_packages of a query by a given query id if authenticated' do

    before do
      login_as(user_1)
    end

    subject { instance.call(user: user_1, query_id: query.id) } 

    it 'returns work_packages of query as result ' do
      expect(subject.result)
        .to match_array(query.results.work_packages)
    end

    it 'is a success' do
      expect(subject)
        .to be_success
    end

  end
  
  context 'does not resolve work_packages of a query by a given query id if not authenticated' do

    before do
      login_as(user_2_without_permission)
    end

    subject { instance.call(user: user_2_without_permission, query_id: query.id) } 

    it 'raises ActiveRecord::RecordNotFound' do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end
  
  context 'does not resolve work_packages of a query by a given query id if not member of project' do

    before do
      login_as(user_3_not_member)
    end

    subject { instance.call(user: user_3_not_member, query_id: query.id) } 

    it 'raises ActiveRecord::RecordNotFound' do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

  context 'does not resolve work_packages if query id is' do

    before do
      login_as(user_1)
    end

    subject { instance.call(user: user_1, query_id: SecureRandom.hex) } 

    it 'invalid and raises ActiveRecord::RecordNotFound' do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end

    subject { instance.call(user: user_1, query_id: nil) } 

    it 'nil and raises ActiveRecord::RecordNotFound' do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

end
