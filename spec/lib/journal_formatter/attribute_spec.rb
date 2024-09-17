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

RSpec.describe JournalFormatter::Attribute do
  describe ".render" do
    let(:journal) { build_stubbed(:work_package_journal) }
    let(:instance) { described_class.new(journal) }

    context "with two string values where one is longer than 100 characters" do
      let(:old_value) { "For strings longer than 100 characters, a line break is added between values for a better readability" }
      let(:new_value) { "Hello, World!" }

      it "adds a newline between values" do
        expect(instance.render("name", [old_value, new_value]))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: "<strong>Name</strong>",
                        linebreak: "<br/>",
                        old: "<i>#{old_value}</i>",
                        new: "<i>#{new_value}</i>"))

        expect(instance.render("name", [old_value, new_value], html: false))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: "Name",
                        linebreak: "\n",
                        old: old_value,
                        new: new_value))
      end
    end
  end
end
