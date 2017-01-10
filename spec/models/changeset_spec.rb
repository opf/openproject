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

describe Changeset, type: :model do
  let(:email) { 'bob@bobbit.org' }

  with_virtual_subversion_repository do
    let(:changeset) {
      FactoryGirl.build(:changeset,
                        repository: repository,
                        revision: '1',
                        committer: email,
                        comments: 'Initial commit')
    }
  end

  shared_examples_for 'valid changeset' do
    it { expect(changeset.revision).to eq('1') }

    it { expect(changeset.committer).to eq(email) }

    it { expect(changeset.comments).to eq('Initial commit') }

    describe 'journal' do
      let(:journal) { changeset.journals.first }

      it { expect(journal.user).to eq(journal_user) }

      it { expect(journal.notes).to eq(changeset.comments) }
    end
  end

  describe 'assign_openproject user' do
    describe 'w/o user' do
      before do changeset.save! end

      it_behaves_like 'valid changeset' do
        let(:journal_user) { User.anonymous }
      end
    end

    describe 'with user is committer' do
      let!(:committer) { FactoryGirl.create(:user, login: email) }

      before do changeset.save! end

      it_behaves_like 'valid changeset' do
        let(:journal_user) { committer }
      end
    end

    describe 'current user is not committer' do
      let(:current_user) { FactoryGirl.create(:user) }
      let!(:committer) { FactoryGirl.create(:user, login: email) }

      before do
        allow(User).to receive(:current).and_return current_user

        changeset.save!
      end

      it_behaves_like 'valid changeset' do
        let(:journal_user) { committer }
      end
    end
  end
end
