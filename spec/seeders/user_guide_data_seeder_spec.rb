# frozen_string_literal: true

# -- copyright
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
# ++
#++

require "spec_helper"

RSpec.describe UserGuideDataSeeder do
  include_context "with user guide seed data"

  let(:project) { Project.find_by!(identifier: "user-guide") }
  let(:customer_feedback) { project.forums.find_by!(name: "Customer feedback") }

  def seed_again
    RootSeeder.new(seed_development_data: false).seed_data! do |root_seeder|
      described_class.new(root_seeder.seed_data).seed!
    end
  end

  it "seeds the basic data first" do
    expect(Type.pluck(:name)).to include("Task", "Bug")
  end

  it "seeds the user guide project with the modules its navigation shows" do
    expect(project.enabled_module_names).to include("work_package_tracking", "forums", "meetings")
  end

  it "makes Mia Bayer the project admin" do
    mia = User.find_by!(login: "mia.bayer")

    expect(mia.roles_for_project(project).map(&:name)).to contain_exactly("Project admin")
  end

  it "seeds the forums in order, the last one empty", :aggregate_failures do
    expect(project.forums.order(:position).map(&:name))
      .to eq(["Customer feedback", "Usability topics", "Download and installation"])
    expect(project.forums.find_by!(name: "Download and installation").topics).to be_empty
  end

  it "pins and locks the topic about handling feedback" do
    expect(customer_feedback.topics.find_by!(subject: "How we handle your feedback")).to be_sticky.and be_locked
  end

  it "keeps the forum counters in step with the seeded messages", :aggregate_failures do
    expect(customer_feedback.topics_count).to eq(3)
    expect(customer_feedback.messages_count).to eq(customer_feedback.messages.count)
  end

  it "seeds nothing more when run again on a seeded database" do
    expect { seed_again }.not_to change { [Type.count, User.count, Project.count, Member.count, Message.count] }
  end
end
