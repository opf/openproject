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

RSpec.describe JournalFormatter::Percentage do
  describe ".render" do
    let(:journal) { build_stubbed(:work_package_journal) }
    let(:instance) { described_class.new(journal) }

    context "when setting new value" do
      let(:old_value) { nil }
      let(:new_value) { 33 }

      it "renders the new value" do
        expect(instance.render("done_ratio", [old_value, new_value]))
          .to eq(I18n.t(:text_journal_set_to,
                        label: "<strong>% Complete</strong>",
                        value: "<i>#{new_value}%</i>"))

        expect(instance.render("done_ratio", [old_value, new_value], html: false))
          .to eq(I18n.t(:text_journal_set_to,
                        label: "% Complete",
                        value: "#{new_value}%"))
      end
    end

    context "when changing value" do
      let(:old_value) { 98 }
      let(:new_value) { 33 }

      it "renders the change from old to new value" do
        expect(instance.render("done_ratio", [old_value, new_value]))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: "<strong>% Complete</strong>",
                        linebreak: nil,
                        old: "<i>#{old_value}%</i>",
                        new: "<i>#{new_value}%</i>"))

        expect(instance.render("done_ratio", [old_value, new_value], html: false))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: "% Complete",
                        linebreak: nil,
                        old: "#{old_value}%",
                        new: "#{new_value}%"))
      end
    end

    context "when removing the value" do
      let(:old_value) { 98 }
      let(:new_value) { nil }

      it "renders as removed instead of displaying 'changed to 0'" do
        expect(instance.render("done_ratio", [old_value, new_value]))
          .to eq(I18n.t(:text_journal_deleted,
                        label: "<strong>% Complete</strong>",
                        old: "<strike><i>#{old_value}%</i></strike>"))

        expect(instance.render("done_ratio", [old_value, new_value], html: false))
          .to eq(I18n.t(:text_journal_deleted,
                        label: "% Complete",
                        old: "#{old_value}%"))
      end
    end
  end
end
