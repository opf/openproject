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
require_relative "backlog"

RSpec.describe Pages::Backlog do
  subject(:backlog_page) { described_class.new(project) }

  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:sprint) { build_stubbed(:sprint) }

  describe "#drag_work_package" do
    it "raises when neither before nor into is provided" do
      expect { backlog_page.drag_work_package(work_package) }
        .to raise_error(ArgumentError, "You must specify either before or into")
    end

    it "raises when both before and into are provided" do
      expect { backlog_page.drag_work_package(work_package, before: work_package, into: sprint) }
        .to raise_error(ArgumentError, "You must specify either before or into")
    end
  end
end
