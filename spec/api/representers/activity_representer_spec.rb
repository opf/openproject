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

describe ::API::V3::Activities::ActivityRepresenter do
  let(:work_package) { FactoryGirl.build(:work_package) }
  let(:journal) { FactoryGirl.build(:work_package_journal, journable: work_package) }
  let(:model) { ::API::V3::Activities::ActivityModel.new(journal) }
  let(:representer) { described_class.new(model) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('Activity'.to_json).at_path('_type') }

    it { should have_json_type(Object).at_path('_links') }
    it 'should link to self' do
      expect(subject).to have_json_path('_links/self/href')
    end

    describe 'activity' do
      it { should have_json_path('id') }
      it { should have_json_path('version') }
      it { should have_json_path('comment') }
      it { should have_json_path('details') }
      it { should have_json_path('htmlDetails') }
      it { should have_json_path('createdAt') }

      it 'should link to work package' do
        expect(subject).to have_json_path('_links/workPackage/href')
      end

      it 'should link to user' do
        expect(subject).to have_json_path('_links/user/href')
      end
    end
  end
end
