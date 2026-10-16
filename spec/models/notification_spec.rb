# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++
require "spec_helper"

RSpec.describe Notification do
  describe "Associations" do
    it { is_expected.to belong_to(:journal) }
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:actor).class_name("User") }
    it { is_expected.to belong_to(:recipient).class_name("User") }

    it { is_expected.to have_one(:reminder_notification).dependent(:destroy) }
    it { is_expected.to have_one(:reminder).through(:reminder_notification) }
  end

  describe "Enums" do
    it do
      expect(subject).to define_enum_for(:reason)
        .with_values(
          mentioned: 0,
          assigned: 1,
          watched: 2,
          subscribed: 3,
          commented: 4,
          created: 5,
          processed: 6,
          prioritized: 7,
          scheduled: 8,
          responsible: 9,
          date_alert_start_date: 10,
          date_alert_due_date: 11,
          shared: 12,
          reminder: 13
        )
        .with_prefix
        .backed_by_column_of_type(:integer)
    end
  end

  describe ".save" do
    context "for a non existing journal (e.g. because it has been deleted)" do
      let(:notification) { build(:notification) }

      it "raises an error" do
        notification.journal_id = 99999
        expect { notification.save }
          .to raise_error ActiveRecord::InvalidForeignKey
      end
    end
  end
end
