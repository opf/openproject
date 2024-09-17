#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"
require Rails.root.join("db/migrate/20220818074150_fix_invalid_journals.rb")

RSpec.describe FixInvalidJournals, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject(:run_migration) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let(:attachment) { create :attachment }
  let(:custom_field) { create :custom_field }
  let!(:work_package_journals) { create_list :work_package_journal, 3 }

  let!(:valid_journal) do
    user = create :user

    ActiveRecord::Base.connection.execute("
      INSERT INTO journals
      (journable_type, data_type, data_id, user_id, created_at, updated_at, validity_period)
      VALUES
      ('WikiContent', 'Journal::WikiContentJournal', 0, #{user.id}, '2023-07-01', '2023-07-01', '[\"2021-05-03 12:53:28.245599+00\",)')
    ")

    journal = Journal.last

    ActiveRecord::Base.connection.execute("
      INSERT INTO attachable_journals
        (journal_id, attachment_id, filename)
      VALUES
        (#{journal.id}, #{attachment.id}, 'foo')
    ")

    ActiveRecord::Base.connection.execute("
      INSERT INTO customizable_journals
        (journal_id, custom_field_id, value)
      VALUES
        (#{journal.id}, #{custom_field.id}, 'foo')
    ")

    journal
  end

  let!(:invalid_journal) do
    user = create :user

    ActiveRecord::Base.connection.execute("
      INSERT INTO journals
      (journable_type, data_type, data_id, user_id, created_at, updated_at, validity_period)
      VALUES
      ('WikiContent', 'Journal::FooJournal', 0, #{user.id}, '2023-07-01',
       '2023-07-01', '[\"2021-05-03 12:53:28.245599+00\",)')
    ")

    journal = Journal.last

    ActiveRecord::Base.connection.execute("
      INSERT INTO attachable_journals
        (journal_id, attachment_id, filename)
      VALUES
        (#{journal.id}, #{attachment.id}, 'bar')
    ")

    ActiveRecord::Base.connection.execute("
      INSERT INTO customizable_journals
        (journal_id, custom_field_id, value)
      VALUES
        (#{journal.id}, #{custom_field.id}, 'bar')
    ")

    journal
  end

  before do
    run_migration
  end

  it "removes invalid journals and its associations", :aggregate_failures do
    expect(Journal.find_by(id: invalid_journal.id)).to be_nil

    expect(Journal::AttachableJournal.find_by(journal_id: invalid_journal.id)).to be_nil
    expect(Journal::CustomizableJournal.find_by(journal_id: invalid_journal.id)).to be_nil

    # Keeps the valid, outdated journal
    expect(Journal.find_by(id: valid_journal.id)).to be_present
    expect(Journal::AttachableJournal.find_by(journal_id: valid_journal.id)).to be_present
    expect(Journal::CustomizableJournal.find_by(journal_id: valid_journal.id)).to be_present

    expect(Journal.find(work_package_journals.map(&:id))).to eq work_package_journals
  end
end
