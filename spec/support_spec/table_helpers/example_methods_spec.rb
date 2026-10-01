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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

module TableHelpers
  RSpec.describe ExampleMethods do
    create_shared_association_defaults_for_work_package_factory

    describe "change_work_packages" do
      let(:fake_today) { Date.new(2022, 6, 16) } # Thursday 16 June 2022
      let(:monday) { Date.new(2022, 6, 20) } # Monday 20 June
      let(:tuesday) { Date.new(2022, 6, 21) }
      let(:thursday) { Date.new(2022, 6, 23) }
      let(:friday) { Date.new(2022, 6, 24) }

      before do
        travel_to(fake_today)
      end

      after do
        travel_back
      end

      it "applies attribute changes to a group of work packages from a visual table representation" do
        main = build_stubbed(:work_package, subject: "main")
        second = build_stubbed(:work_package, subject: "second")
        change_work_packages([main, second], <<~TABLE)
          subject | MTWTFSS | scheduling mode |
          main    | XX      | manual          |
          second  |    XX   | automatic       |
        TABLE
        expect(main.start_date).to eq(monday)
        expect(main.due_date).to eq(tuesday)
        expect(main.schedule_manually).to be(true)
        expect(second.start_date).to eq(thursday)
        expect(second.due_date).to eq(friday)
        expect(second.schedule_manually).to be(false)
      end

      it "does not save changes" do
        main = create(:work_package, subject: "main")
        expect(main.persisted?).to be(true)
        expect(main.has_changes_to_save?).to be(false)
        change_work_packages([main], <<~TABLE)
          subject | MTWTFSS |
          main    | XX      |
        TABLE
        expect(main.has_changes_to_save?).to be(true)
        expect(main.changes).to eq("start_date" => [nil, monday], "due_date" => [nil, tuesday])
      end
    end
  end
end
