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

describe JournalVersion, type: :model do
  let!(:work_package) do
    wp = FactoryBot.build(:work_package)
    wp.journal_notes = 'foobar!'

    wp.save!
    wp
  end

  subject { ::JournalVersion.find_by!(journable_type: 'WorkPackage', journable_id: work_package.id) }

  before do
    work_package
    subject
  end

  it 'is created when the work package is created' do
    expect(subject.version).to eq 1
  end

  it 'is incremented when the work package is journaled' do
    work_package.subject = 'Foobar!'
    work_package.journal_notes = 'My comment'
    work_package.save!

    work_package.reload

    expect(work_package.journals.count).to eq 2
    expect(work_package.journals.first.version).to eq 1
    expect(work_package.journals.last.version).to eq 2

    subject.reload
    expect(subject.version).to eq 2
  end

  it 'is removed when the work package is removed' do
    expect(subject).to be_present

    work_package.destroy!

    expect { subject.reload }.to raise_error ActiveRecord::RecordNotFound
  end
end
