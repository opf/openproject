# frozen_string_literal: true

# -- copyright
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
# ++

RSpec.shared_examples_for "journaled values for" do |new_values_set:,
                                                     expected_values:,
                                                     expect_new_journal: true,
                                                     expect_predecessor_changed: expect_new_journal,
                                                     expect_journable_update_at_changed: true,
                                                     expected_cause: nil,
                                                     expected_notes: nil|
  def value_or_id(value)
    case value
    when Symbol then public_send(value).id
    when Proc then instance_exec(&value)
    else value
    end
  end

  before do
    new_values_set.each do |property, value|
      journable.public_send("#{property}=", value_or_id(value))
    end
  end

  expected_values.each do |property, (old_value, new_value)|
    context "for #{property}" do
      it "tracks the change from old value #{old_value.inspect} to new value #{new_value.inspect}" do
        journable.save!

        expect(journable.last_journal.old_value_for(property)).to eq(value_or_id(old_value))
        expect(journable.last_journal.new_value_for(property)).to eq(value_or_id(new_value))
      end
    end
  end

  if expected_values.empty?
    it "has no changes tracked" do
      journable.save!

      expect(journable.last_journal.details.except("cause"))
        .to be_empty
    end
  end

  if expect_new_journal
    it "creates a new journal" do
      expect { journable.save! }
        .to change { journable.journals.reload.count }
              .by(1)
    end

    it "the journal has the timestamp of the journable update time for created_at" do
      journable.save!

      expect(journable.last_journal.created_at)
        .to eql(journable.reload.updated_at)
    end

    it "the journal has the timestamp of the journable update time for updated_at" do
      journable.save!

      expect(journable.last_journal.updated_at)
        .to eql(journable.reload.updated_at)
    end

    it "has the updated_at of the journable as the lower bound for validity_period and no upper bound" do
      journable.save!

      expect(journable.last_journal.validity_period)
        .to eql(journable.reload.updated_at...)
    end

    # This is currently only used if there is no predecessor
    if expect_predecessor_changed
      it "sets the upper bound of the preceding journal to be the created_at time of the newly created journal" do
        journable.save!

        former_last_journal = journable.journals.reload[-2]
        expect(former_last_journal.validity_period)
          .to eql(former_last_journal.created_at...journable.last_journal.created_at)
      end

      it "keeps the user of the preceding journal" do
        former_last_journal = journable.last_journal

        journable.save!

        expect(journable.journals.reload[-2].user)
          .to eql(former_last_journal.user)
      end
    end
  else
    it "does not create a new journal" do
      expect { journable.save! }
        .not_to change { journable.journals.reload.count }
    end

    it "keeps the journal's created_at time" do
      expect { journable.save! }
        .not_to change { journable.last_journal.created_at }
    end

    it "updates both the journal's updated_at time and the journable's updated_at time to the same value" do
      expect { journable.save! }
       .to change { journable.last_journal.updated_at }

      expect(journable.last_journal.updated_at)
        .to eql(journable.reload.updated_at)
    end

    it "keeps created_at of the journal as the lower bound for validity_period and no upper bound" do
      journable.save!

      expect(journable.last_journal.validity_period)
        .to eql(journable.last_journal.created_at...)
    end
  end

  it "has the current user as the journal's user" do
    journable.save!

    expect(journable.last_journal.user)
      .to eql(current_user)
  end

  it "sends an OpenProject JOURNAL_CREATED notification" do
    allow(OpenProject::Notifications)
      .to receive(:send)

    journable.save!

    expect(OpenProject::Notifications)
      .to have_received(:send)
            .with(OpenProject::Events::JOURNAL_CREATED, anything)
            .once

    # only one notification is sent even if the journable is saved multiple times
    journable.save!

    expect(OpenProject::Notifications)
    .to have_received(:send)
          .with(OpenProject::Events::JOURNAL_CREATED, anything)
          .once
  end

  if expected_cause
    it "has the expected cause" do
      journable.save!

      expect(journable.last_journal.cause)
        .to eql(expected_cause)
    end
  else
    it "has no cause" do
      journable.save!

      expect(journable.last_journal.cause)
        .to be_empty
    end
  end

  if expected_notes
    it "has the expected notes" do
      journable.save!

      expect(journable.last_journal.notes)
        .to eql(expected_notes)
    end
  else
    it "has no notes" do
      journable.save!

      expect(journable.last_journal.notes)
        .to be_empty
    end
  end

  if expect_journable_update_at_changed
    it "updates the updated_at time of the journable" do
      # Using this complicated form of writing to avoid problems
      # e.g. with reloading before the journable is initially saved
      updated_at_before = journable.updated_at

      journable.save!

      expect(journable.reload.updated_at)
        .not_to eql(updated_at_before)
    end
  else
    it "keeps the updated_at time of the journable" do
      # Using this complicated form of writing to avoid problems
      # e.g. with reloading before the journable is initially saved
      expect { journable.save! }
        .not_to change { journable.reload.updated_at }
    end
  end
end

RSpec.shared_examples_for "no journaled value changes for" do |new_values_set:, expect_journable_update_at_changed: false|
  def value_or_id(value)
    value.is_a?(Symbol) ? public_send(value).id : value
  end

  before do
    new_values_set.each do |property, value|
      journable.public_send("#{property}=", value_or_id(value))
    end
  end

  it "does not create a new journal" do
    expect { journable.save! }
      .not_to change(Journal, :count)
  end

  it "does not update the updated_at time of the last journal" do
    expect { journable.save! }
      .not_to change {
        journable.journals.reload.last.updated_at
      }
  end

  unless expect_journable_update_at_changed
    it "does not update the updated_at time of the journable" do
      expect { journable.save! }
        .not_to change(journable, :updated_at)
    end
  end

  it "does not send an OpenProject notification" do
    allow(OpenProject::Notifications)
      .to receive(:send)

    journable.save!

    expect(OpenProject::Notifications)
      .not_to have_received(:send)
  end

  it "has a data journal" do
    journable.save!

    expect(journable.last_journal.data)
      .not_to be_nil
  end
end
