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

RSpec.describe OpenProject::TextFormatting::Helpers::AccessibleLinkLabel do
  subject(:helper) { Class.new { include OpenProject::TextFormatting::Helpers::AccessibleLinkLabel }.new }

  describe "#accessible_link_label" do
    it "combines visible text and description using the localized format" do
      expect(helper.accessible_link_label("Monthly coordination", "A dynamic link to a meeting placed using a macro."))
        .to eq("Monthly coordination: A dynamic link to a meeting placed using a macro.")
    end

    it "strips HTML from visible text and description" do
      expect(helper.accessible_link_label(
               "<strong>Monthly</strong> coordination",
               "A <em>dynamic</em> link placed using a macro."
             )).to eq("Monthly coordination: A dynamic link placed using a macro.")
    end

    it "strips escaped HTML from visible text and description" do
      expect(helper.accessible_link_label(
               "&lt;strong&gt;Monthly&lt;/strong&gt; coordination",
               "A &lt;em&gt;dynamic&lt;/em&gt; link placed using a macro."
             )).to eq("Monthly coordination: A dynamic link placed using a macro.")
    end

    it "preserves plain text containing angle brackets" do
      expect(helper.accessible_link_label("I <3 Ruby", "A dynamic link placed using a macro."))
        .to eq("I <3 Ruby: A dynamic link placed using a macro.")
    end
  end
end
