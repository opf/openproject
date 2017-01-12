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

describe ::API::V3::Activities::ActivityRepresenter do
  let(:current_user) { FactoryGirl.create(:user,  member_in_project: project, member_through_role: role) }
  let(:work_package) { FactoryGirl.build(:work_package) }
  let(:journal) { Journal::AggregatedJournal.aggregated_journals.first }
  let(:project) { work_package.project }
  let(:permissions) { %i(edit_own_work_package_notes) }
  let(:role) { FactoryGirl.create :role, permissions: permissions }
  let(:representer) { described_class.new(journal, current_user: current_user) }

  before do
    allow(User).to receive(:current).and_return(current_user)
    work_package.save!
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('Activity'.to_json).at_path('_type') }

    it { is_expected.to have_json_type(Object).at_path('_links') }
    it 'should link to self' do
      expect(subject).to have_json_path('_links/self/href')
    end

    describe 'activity' do
      it { is_expected.to have_json_path('id') }
      it { is_expected.to have_json_path('version') }

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { journal.created_at }
        let(:json_path) { 'createdAt' }
      end

      it_behaves_like 'API V3 formattable', 'comment' do
        let(:format) { 'textile' }
        let(:raw) { journal.notes }
        let(:html) { "#{journal.notes}" }
      end

      describe 'details' do
        it { is_expected.to have_json_path('details') }

        it { is_expected.to have_json_size(journal.details.count).at_path('details') }

        it 'should render all details as formattable' do
          (0..journal.details.count - 1).each do |x|
            is_expected.to be_json_eql('custom'.to_json).at_path("details/#{x}/format")
            is_expected.to have_json_path("details/#{x}/raw")
            is_expected.to have_json_path("details/#{x}/html")
          end
        end
      end

      it 'should link to work package' do
        expect(subject).to have_json_path('_links/workPackage/href')
      end

      it 'should link to user' do
        expect(subject).to have_json_path('_links/user/href')
      end

      it 'should link to update' do
        expect(subject).to have_json_path('_links/update/href')
      end
    end
  end
end
