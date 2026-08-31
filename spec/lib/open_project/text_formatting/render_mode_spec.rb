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

RSpec.describe OpenProject::TextFormatting::RenderMode do
  describe ".resolve" do
    context "with :in_app_html" do
      it "produces the in-app default trio" do
        expect(described_class.resolve(:in_app_html)).to eq(
          only_path: true,
          static_html: false,
          plain_text: false
        )
      end
    end

    context "with :external_html" do
      it "produces absolute URLs and static-HTML rendering" do
        expect(described_class.resolve(:external_html)).to eq(
          only_path: false,
          static_html: true,
          plain_text: false
        )
      end
    end

    context "with :external_text" do
      it "produces absolute URLs and plain-text output" do
        expect(described_class.resolve(:external_text)).to eq(
          only_path: false,
          static_html: false,
          plain_text: true
        )
      end
    end

    context "with an explicit primitive flag" do
      it "lets only_path override while keeping the rest of the mode's defaults" do
        expect(described_class.resolve(:external_html, only_path: true)).to eq(
          only_path: true,
          static_html: true,
          plain_text: false
        )
      end

      it "lets an explicit false override the mode's true default" do
        expect(described_class.resolve(:external_html, static_html: false)).to eq(
          only_path: false,
          static_html: false,
          plain_text: false
        )
      end

      it "ignores a nil override (treats it as 'not passed')" do
        expect(described_class.resolve(:external_html, plain_text: nil)).to eq(
          only_path: false,
          static_html: true,
          plain_text: false
        )
      end
    end

    context "with an unknown mode" do
      it "raises ArgumentError naming the bad value" do
        expect { described_class.resolve(:nonsense) }
          .to raise_error(ArgumentError, /render_mode.*nonsense/)
      end
    end
  end
end
