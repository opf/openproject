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

RSpec.describe I18n, "pluralization", type: :helper do
  describe "with slowenian language and the :two plural key missing" do
    before do
      I18n.locale = :sl
      allow(I18n.backend)
        .to(receive(:lookup))
        .and_call_original

      allow(I18n.backend)
        .to(receive(:lookup))
        .with(:sl, :label_x_projects, any_args)
        .and_return({ one: "1 projekt", other: "%<count>s projektov", zero: "Brez projektov" })
    end

    it "allows to pluralize without exceptions (Regression #37607)", :aggregate_failures do
      expect(I18n.t(:label_x_projects, count: 0)).to eq "Brez projektov"
      expect(I18n.t(:label_x_projects, count: 1)).to eq "1 projekt"
      expect(I18n.t(:label_x_projects, count: 2)).to eq "2 projektov"
      expect(I18n.t(:label_x_projects, count: 10)).to eq "10 projektov"
      expect(I18n.t(:label_x_projects, count: 20)).to eq "20 projektov"
    end
  end

  describe "with slowenian language and the :other plural key missing" do
    before do
      I18n.locale = :sl
      allow(I18n.backend)
        .to(receive(:lookup))
        .and_call_original

      allow(I18n.backend)
        .to(receive(:lookup))
        .with(:sl, :label_x_projects, any_args)
        .and_return({ one: "1 projekt", zero: "Brez projektov" })
    end

    it "falls back to english translation (Regression #37607)", :aggregate_failures do
      expect(I18n.t(:label_x_projects, count: 0)).to eq "Brez projektov"
      expect(I18n.t(:label_x_projects, count: 1)).to eq "1 projekt"
      expect(I18n.t(:label_x_projects, count: 2)).to eq "2 projects"
      expect(I18n.t(:label_x_projects, count: 10)).to eq "10 projects"
      expect(I18n.t(:label_x_projects, count: 20)).to eq "20 projects"
    end
  end
end
