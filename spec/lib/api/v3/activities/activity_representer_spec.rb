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

describe ::API::V3::Activities::ActivityRepresenter do
  let(:current_user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u)
        .to receive(:allowed_to?) do |checked_permission, project|
        project == work_package.project && permissions.include?(checked_permission)
      end
    end
  end
  let(:other_user) { FactoryBot.build_stubbed(:user) }
  let(:work_package) { journal.journable }
  let(:notes) { "My notes" }
  let(:journal) do
    FactoryBot.build_stubbed(:work_package_journal, notes: notes).tap do |journal|
      allow(journal)
        .to receive(:notes_id)
        .and_return(journal.id)
      allow(journal)
        .to receive(:get_changes)
        .and_return(changes)
    end
  end
  let(:changes) { { subject: ["first subject", "second subject"] } }
  let(:permissions) { %i(edit_work_package_notes) }
  let(:representer) { described_class.new(journal, current_user: current_user) }

  before do
    login_as(current_user)
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe 'type' do
      it { is_expected.to be_json_eql('Activity::Comment'.to_json).at_path('_type') }

      context 'if notes are empty' do
        let(:notes) { '' }

        it { is_expected.to be_json_eql('Activity'.to_json).at_path('_type') }
      end

      context 'if notes and changes are empty' do
        let(:notes) { '' }
        let(:changes) { {} }

        it { is_expected.to be_json_eql('Activity::Comment'.to_json).at_path('_type') }
      end
    end

    it { is_expected.to have_json_type(Object).at_path('_links') }
    it 'should link to self' do
      expect(subject).to have_json_path('_links/self/href')
    end

    it { is_expected.to have_json_path('id') }
    it { is_expected.to have_json_path('version') }

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { journal.created_at }
      let(:json_path) { 'createdAt' }
    end

    describe 'comment' do
      it_behaves_like 'API V3 formattable', 'comment' do
        let(:format) { 'markdown' }
        let(:raw) { journal.notes }
        let(:html) { "<p>#{journal.notes}</p>" }
      end

      context 'if having no change and notes' do
        let(:notes) { "" }
        let(:changes) { {} }

        it_behaves_like 'API V3 formattable', 'comment' do
          let(:format) { 'markdown' }
          let(:raw) { "_#{I18n.t(:'journals.changes_retracted')}_" }
          let(:html) { "<p><em>#{I18n.t(:'journals.changes_retracted')}</em></p>" }
        end
      end
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

    context 'for a non own journal' do
      context 'when having edit_work_package_notes' do
        it 'should link to update' do
          expect(subject).to have_json_path('_links/update/href')
        end
      end

      context 'when only having edit_own_work_package_notes' do
        let(:permissions) { %i(edit_own_work_package_notes) }

        it 'has no update link' do
          expect(subject)
            .not_to have_json_path('_links/update/href')
        end
      end
    end
  end
end
