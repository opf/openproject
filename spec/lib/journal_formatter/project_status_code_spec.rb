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

RSpec.describe OpenProject::JournalFormatter::ProjectStatusCode do
  def status_code_as_integer(status)
    Project.status_codes.fetch(status, nil)
  end

  describe "#render" do
    let(:journal) { build_stubbed(:project_journal) }
    let(:instance) { described_class.new(journal) }
    let(:status_code_key) { "status_code" }

    context "when setting a status" do
      let(:old_value) { nil }
      let(:new_value) { status_code_as_integer("off_track") }
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>Project status</strong>",
               value: "<i>Off track</i>")
      end

      it { expect(instance.render(status_code_key, [old_value, new_value])).to eq(expected) }
    end

    context "when deleting a status" do
      let(:old_value) { status_code_as_integer("discontinued") }
      let(:new_value) { nil }
      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>Project status</strong>",
               old: "<strike><i>Discontinued</i></strike>")
      end

      it { expect(instance.render(status_code_key, [old_value, new_value])).to eq(expected) }
    end

    context "when modifying a status" do
      let(:old_value) { status_code_as_integer("off_track") }
      let(:new_value) { status_code_as_integer("on_track") }
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Project status</strong>",
               linebreak: nil,
               old: "<i>Off track</i>",
               new: "<i>On track</i>")
      end

      it { expect(instance.render(status_code_key, [old_value, new_value])).to eq(expected) }
    end
  end
end
