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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Projects::DefaultRemainingWorkSettings, type: :model do
  shared_let(:admin) { create(:admin) }

  context "when creating a project" do
    subject(:project) do
      Projects::CreateService.new(user: admin).call(name: "New project", identifier: "new-project").result
    end

    it "enables logged time reducing remaining work" do
      expect(project.logged_time_reduces_remaining_work).to be(true)
    end

    it "makes remaining work read only" do
      expect(project.remaining_work_read_only).to be(true)
    end
  end

  context "when creating a project with the settings disabled" do
    subject(:project) do
      Projects::CreateService
        .new(user: admin)
        .call(name: "New project",
              identifier: "new-project",
              logged_time_reduces_remaining_work: false,
              remaining_work_read_only: false)
        .result
    end

    it "keeps the provided values" do
      expect(project.logged_time_reduces_remaining_work).to be(false)
      expect(project.remaining_work_read_only).to be(false)
    end
  end

  context "when copying a project that has the settings disabled" do
    let(:source) do
      create(:project, logged_time_reduces_remaining_work: false, remaining_work_read_only: false)
    end

    subject(:project) do
      Projects::CopyService
        .new(user: admin, source:)
        .call(target_project_params: { name: "Copy", identifier: "copy" }, only: [])
        .result
    end

    it "keeps the values of the source project" do
      expect(project.logged_time_reduces_remaining_work).to be(false)
      expect(project.remaining_work_read_only).to be(false)
    end
  end

  context "for an existing project" do
    let(:project) { create(:project) }

    it "has both settings disabled" do
      expect(project.logged_time_reduces_remaining_work).to be_nil
      expect(project.remaining_work_read_only).to be_nil
    end
  end
end
