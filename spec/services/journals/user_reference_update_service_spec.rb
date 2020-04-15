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

describe Journals::UserReferenceUpdateService, type: :model do
  let!(:work_package) { FactoryBot.create :work_package }
  let!(:doomed_user) { work_package.author }
  let!(:other_user) { FactoryBot.create(:user) }
  let!(:data1) do
    FactoryBot.build(:journal_work_package_journal,
                     subject: work_package.subject,
                     status_id: work_package.status_id,
                     type_id: work_package.type_id,
                     author_id: doomed_user.id,
                     assigned_to_id: other_user.id,
                     responsible_id: doomed_user.id,
                     project_id: work_package.project_id)
  end
  let!(:data2) do
    FactoryBot.build(:journal_work_package_journal,
                     subject: work_package.subject,
                     status_id: work_package.status_id,
                     type_id: work_package.type_id,
                     author_id: doomed_user.id,
                     assigned_to_id: doomed_user.id,
                     responsible_id: other_user.id,
                     project_id: work_package.project_id)
  end
  let!(:doomed_user_journal) do
    FactoryBot.create :work_package_journal,
                      notes: '1',
                      user: doomed_user,
                      journable_id: work_package.id,
                      data: data1
  end
  let!(:some_other_journal) do
    FactoryBot.create :work_package_journal,
                      notes: '2',
                      journable_id: work_package.id,
                      data: data2
  end

  describe '.call' do
    subject do
      described_class
        .new(doomed_user)
        .call(DeletedUser.first)
    end

    before do
      subject
    end

    it "is success" do
      expect(subject)
        .to be_success
    end

    it "marks only the user's journal as deleted" do
      expect(doomed_user_journal.reload.user.is_a?(DeletedUser)).to be_truthy
      expect(some_other_journal.reload.user.is_a?(DeletedUser)).to be_falsey
    end

    it "marks the assignee stored in the WorkPackageJournal as deleted" do
      expect(data2.reload.assigned_to_id)
        .to eql(DeletedUser.first.id)

      expect(data1.reload.assigned_to_id)
        .to eql(other_user.id)
    end

    it "marks the responsible stored in the WorkPackageJournal as deleted" do
      expect(data1.reload.responsible_id)
        .to eql(DeletedUser.first.id)

      expect(data2.reload.responsible_id)
        .to eql(other_user.id)
    end
  end
end
