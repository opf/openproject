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

RSpec.describe AI::TextTransforms::PaneParamsContract do
  let(:valid) { { request_id: SecureRandom.uuid, scope: "document" } }

  def errors_for(params)
    described_class.new.call(valid.merge(params)).errors
  end

  it "accepts a request id and a scope without a context" do
    expect(errors_for({})).to be_empty
  end

  {
    "a work package" => { work_package_id: "7" },
    "a project and a type" => { project_id: "1", type_id: "2" },
    "blank context ids" => { work_package_id: "", project_id: "1", type_id: "2" },
    "an action and input" => { action_id: "3", input: "Text" },
    "a retry" => { retry_of: SecureRandom.uuid },
    "a poll position and state" => { after: "0", state: "done" }
  }.each do |description, params|
    it "accepts #{description}" do
      expect(errors_for(params)).to be_empty
    end
  end

  {
    "a request id that is not a UUID" => [{ request_id: "pane-1" }, :request_id, "must be a UUID (version 4)."],
    "a missing request id" => [{ request_id: nil }, :request_id, "must be filled."],
    "an unknown scope" => [{ scope: "page" }, :scope, "must be one of: document, selection."],
    "a non-numeric action id" => [{ action_id: "fix" }, :action_id, "must be an integer."],
    "an unknown state" => [{ state: "paused" }, :state, "must be one of: generating, done, failed, stopped, cancelled."],
    "a work package together with a project" =>
      [{ work_package_id: "7", project_id: "1", type_id: "2" }, :project_id, "must not be combined with a work package."],
    "a project without a type" => [{ project_id: "1" }, :type_id, "must be given together with a project."],
    "a type without a project" => [{ type_id: "2" }, :type_id, "must be given together with a project."],
    "a retry together with an action" =>
      [{ retry_of: SecureRandom.uuid, action_id: "3" }, :retry_of, "must not be combined with an action or input."],
    "a retry that is not a UUID" => [{ retry_of: "run-1" }, :retry_of, "must be a UUID (version 4)."]
  }.each do |description, (params, key, message)|
    it "rejects #{description}" do
      expect(errors_for(params)[key]).to contain_exactly(message)
    end
  end

  it "rejects input over the maximum length of a run" do
    input = "x" * (AI::TextTransformRun::MAX_INPUT_LENGTH + 1)

    expect(errors_for(input:)[:input]).to be_present
  end
end
