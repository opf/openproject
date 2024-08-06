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

RSpec.describe OpenProject::JournalFormatter::IgnoreNonWorkingDays do
  let(:klass) { described_class }
  let(:id) { 1 }
  let(:journal) do
    instance_double(Journal, journable: WorkPackage.new)
  end
  let(:instance) { klass.new(journal) }
  let(:key) { :ignore_non_working_days }

  describe "#render" do
    context "when setting the old value to false, and the new value to true" do
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>Working days</strong>",
               value: "<i>include non-working days</i>")
      end

      it { expect(instance.render(key, [false, true])).to eq(expected) }
    end

    context "when setting the old value to true, and the new value to false" do
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>Working days</strong>",
               value: "<i>working days only</i>")
      end

      it { expect(instance.render(key, [true, false])).to eq(expected) }
    end
  end
end
