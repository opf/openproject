#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
#++require 'rspec'

require 'spec_helper'

describe Journal::AggregatedJournal, type: :model do
  let(:work_package) {
    FactoryGirl.build(:work_package)
  }
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:initial_author) { user1 }

  subject { described_class.all }

  def aggregated_journal_for(journal)
    Journal::AggregatedJournal.new(journal.attributes, without_protection: true)
  end

  before do
    allow(User).to receive(:current).and_return(initial_author)
    work_package.save!
  end

  it 'returns the one and only journal' do
    is_expected.to match_array [aggregated_journal_for(work_package.journals.first)]
  end

  context 'WP updated immediately after last change' do
    before do
      allow(User).to receive(:current).and_return(new_author)
      work_package.status = FactoryGirl.build(:status)
      work_package.save!
    end

    context 'by author of last change' do
      let(:new_author) { initial_author }

      it 'returns a single aggregated journal' do
        is_expected.to match_array [aggregated_journal_for(work_package.journals.second)]
      end
    end

    context 'by a different author' do
      let(:new_author) { user2 }

      it 'returns both journals' do
        is_expected.to match_array [aggregated_journal_for(work_package.journals.first),
                                    aggregated_journal_for(work_package.journals.second)]
      end
    end
  end
end
