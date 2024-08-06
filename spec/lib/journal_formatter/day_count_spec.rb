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

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper.rb")

RSpec.describe JournalFormatter::DayCount do
  let(:klass) { described_class }
  let(:id) { 1 }
  let(:journal) do
    instance_double(Journal, journable: WorkPackage.new)
  end
  let(:instance) { klass.new(journal) }
  let(:key) { :duration }

  describe "#render" do
    describe "when setting the old value to 1 day, and the new value to 3 days" do
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Duration</strong>",
               old: "<i>1 day</i>",
               new: "<i>3 days</i>",
               linebreak: "")
      end

      it { expect(instance.render(key, [1, 3])).to eq(expected) }
    end

    describe "when setting the initial value to 3 days" do
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>Duration</strong>",
               value: "<i>3 days</i>")
      end

      it { expect(instance.render(key, [nil, 3])).to eq(expected) }
    end

    describe "when deleting the initial value of 3 days" do
      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>Duration</strong>",
               old: "<strike><i>3 days</i></strike>")
      end

      it { expect(instance.render(key, [3, nil])).to eq(expected) }
    end
  end
end
