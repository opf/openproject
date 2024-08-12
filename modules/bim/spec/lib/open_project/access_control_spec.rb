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

RSpec.describe OpenProject::AccessControl do
  describe ".sorted_module_names" do
    context "with bim disabled" do
      before do
        allow(OpenProject::Configuration)
          .to receive(:bim?)
          .and_return false
      end

      context "if including disabled modules" do
        it "includes the bim module" do
          expect(subject.sorted_module_names)
            .to include("bim")
        end
      end

      context "if excluding disabled modules" do
        it "does not include the bim module" do
          expect(subject.sorted_module_names(include_disabled: false))
            .not_to include("bim")
        end
      end
    end

    context "with bim enabled" do
      before do
        allow(OpenProject::Configuration)
          .to receive(:bim?)
          .and_return true
      end

      context "if including disabled modules" do
        it "includes the bim module" do
          expect(subject.sorted_module_names)
            .to include("bim")
        end
      end

      context "if excluding disabled modules" do
        it "includes the bim module" do
          expect(subject.sorted_module_names(include_disabled: false))
            .to include("bim")
        end
      end
    end
  end
end
