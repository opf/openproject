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

RSpec.describe TestManagement::TestCasesQuery do
  let(:project) { create(:project) }
  let(:root) { create(:tm_suite, project:, name: "Accounts") }
  let(:child) { create(:tm_suite, project:, parent: root, name: "Sign in") }
  let(:other_folder) { create(:tm_suite, project:, name: "Reports") }
  let!(:in_root) { create(:tm_test_case, project:, suite: root, title: "Root case", priority: "high") }
  let!(:in_child) { create(:tm_test_case, project:, suite: child, title: "Child case", priority: "low") }
  let!(:elsewhere) { create(:tm_test_case, project:, suite: other_folder, title: "Report case") }
  let!(:unfiled) { create(:tm_test_case, project:, title: "Loose case") }

  def query(params = {})
    described_class.new(project, params)
  end

  it "includes the folder subtree" do
    expect(query(suite_id: root.id.to_s).results).to contain_exactly(in_root, in_child)
  end

  it "selects unfiled cases for suite_id=root" do
    q = query(suite_id: "root")
    expect(q).to be_unfiled
    expect(q.results).to contain_exactly(unfiled)
  end

  it "applies search, status and priority" do
    expect(query(suite_id: root.id.to_s, priority: "low").results).to contain_exactly(in_child)
    expect(query(q: "report").results).to contain_exactly(elsewhere)
    expect(query(status: "nope").results).to be_empty
  end

  it "accepts ActionController::Parameters" do
    params = ActionController::Parameters.new(suite_id: child.id.to_s, controller: "x")
    expect(query(params).results).to contain_exactly(in_child)
  end
end
