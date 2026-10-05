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
require "rake"

RSpec.describe "rake type_schemes:repair" do # rubocop:disable RSpec/DescribeClass
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    Rails.application.load_tasks unless Rake::Task.task_defined?("type_schemes:repair")
  end

  let(:task) { Rake::Task["type_schemes:repair"] }
  let!(:story) { create(:type, name: "Task") }
  let!(:project) { create(:project, types: [story]) }

  after { task.reenable }

  it "defaults to a dry run that writes nothing" do
    expect { task.invoke }.to output(/Mode: dry_run.*Create 'Default Scheme'.*\[apply\]/m).to_stdout
    expect(TypeScheme.count).to eq 0
  end

  it "repairs in apply mode" do
    expect { task.invoke("apply") }.to output(/Mode: apply/).to_stdout

    expect(ProjectTypeScheme.find_by(project_id: project.id).scheme).to be_is_default
  end

  it "reports a consistent system as clean" do
    task.invoke("apply")
    task.reenable

    expect { task.invoke("apply") }.to output(/Nothing to repair/).to_stdout
  end

  it "aborts on an unknown mode" do
    expect { task.invoke("boom") }.to raise_error(SystemExit).and output(/mode must be/).to_stderr
  end
end
