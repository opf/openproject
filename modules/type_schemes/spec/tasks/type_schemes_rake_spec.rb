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

RSpec.describe "rake type_schemes:migrate" do # rubocop:disable RSpec/DescribeClass
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    Rails.application.load_tasks unless Rake::Task.task_defined?("type_schemes:migrate")
  end

  let(:task) { Rake::Task["type_schemes:migrate"] }
  let!(:story) { create(:type) }
  let!(:project) { create(:project, types: [story]) }

  after { task.reenable }

  it "defaults to a dry run" do
    expect { task.invoke }.to output(/Mode: dry_run/).to_stdout
    expect(TypeScheme.count).to eq 0
  end

  it "assigns projects in auto mode" do
    expect { task.invoke("auto") }.to output(/Mode: auto/).to_stdout
    expect(ProjectTypeScheme.find_by(project_id: project.id)).to be_present
  end
end
