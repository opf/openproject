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

RSpec.describe OpenProject::JournalFormatter::ScheduleManually do
  let(:klass) { described_class }
  let(:id) { 1 }
  let(:journal) do
    OpenStruct.new(id:, journable: WorkPackage.new)
  end
  let(:instance) { klass.new(journal) }
  let(:key) { "schedule_manually" }

  describe "#render" do
    describe "with the first value being true, and the second false" do
      let(:expected) do
        I18n.t(:text_journal_label_value,
               label: "<strong>Manual scheduling</strong>",
               value: "deactivated")
      end

      it { expect(instance.render(key, [true, false])).to eq(expected) }
    end

    describe "with the first value being false, and the second true" do
      let(:expected) do
        I18n.t(:text_journal_label_value,
               label: "<strong>Manual scheduling</strong>",
               value: "activated")
      end

      it { expect(instance.render(key, [false, true])).to eq(expected) }
    end
  end
end
