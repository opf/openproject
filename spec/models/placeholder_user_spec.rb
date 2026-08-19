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

RSpec.describe PlaceholderUser do
  subject(:placeholder_user) { create(:placeholder_user, name: "Senior Developer") }

  def filters_for(field, operator, values)
    UserQuery.new.tap { |query| query.where(field, operator, values) }.filters
  end

  describe "validations" do
    it "requires a name" do
      expect(described_class.new(user_filter: filters_for("name", "~", ["dev"]))).not_to be_valid
    end

    it "requires the name to be unique" do
      placeholder_user
      expect(described_class.new(name: "Senior Developer",
                                 user_filter: filters_for("name", "~", ["dev"]))).not_to be_valid
    end

    # A placeholder that just holds a seat in a plan describes nobody.
    it "does not require a filter" do
      expect(described_class.new(name: "Anyone at all")).to be_valid
    end
  end

  describe "the user filter" do
    it "round-trips through the detail table as deserialized filters" do
      placeholder_user.update!(user_filter: filters_for("name", "~", ["dev"]))

      reloaded = described_class.find(placeholder_user.id)

      expect(reloaded.detail).to be_a(PlaceholderUserDetail)
      expect(reloaded.user_filter.map { |f| [f.name, f.operator, f.values] })
        .to eq([[:name, "~", ["dev"]]])
    end

    it "is reported through the owner's dirty tracking" do
      placeholder_user.user_filter = filters_for("name", "~", ["other"])

      expect(placeholder_user.changed).to include("user_filter")
    end
  end

  describe "#candidate_query" do
    let!(:matching) { create(:user, firstname: "Dev", lastname: "Eloper") }
    let!(:other) { create(:user, firstname: "Sales", lastname: "Person") }

    current_user { create(:admin) }

    it "returns the users the filter describes" do
      placeholder_user.update!(user_filter: filters_for("name", "~", ["Eloper"]))

      expect(placeholder_user.candidate_query.results).to contain_exactly(matching)
    end

    it "narrows the candidates to the project's members" do
      project = create(:project, members: { matching => create(:project_role) })
      placeholder_user.update!(user_filter: filters_for("name", "~", ["e"]))

      expect(placeholder_user.candidate_query.results).to include(matching, other)
      expect(placeholder_user.candidate_query(project:).results).to contain_exactly(matching)
    end

    # Membership is applied last, so it wins over a `member` value that made it
    # into the stored criteria.
    it "overrides a member filter smuggled into the stored criteria" do
      project = create(:project, members: { matching => create(:project_role) })
      other_project = create(:project, members: { other => create(:project_role) })
      placeholder_user.update!(user_filter: filters_for("member", "=", [other_project.id.to_s]))

      expect(placeholder_user.candidate_query(project:).results).to contain_exactly(matching)
    end
  end

  describe "#candidate_count" do
    let!(:matching) { create(:user, firstname: "Dev", lastname: "Eloper") }
    let(:resource) { create(:placeholder_user, name: "Developers", user_filter: filters_for("name", "~", ["Eloper"])) }

    current_user { create(:admin) }

    it "counts the users the filter describes" do
      expect(resource.candidate_count).to eq(1)
    end

    it "memoizes per project so a rendered list does not re-resolve the filter" do
      allow(resource).to receive(:candidate_query).and_call_original

      3.times { resource.candidate_count }

      expect(resource).to have_received(:candidate_query).once
    end

    # One incompletely configured resource must not take down the view it is
    # rendered in.
    it "falls back to zero when the filter cannot be resolved" do
      allow(resource).to receive(:candidate_query).and_raise(StandardError, "broken filter")

      expect(resource.candidate_count).to eq(0)
    end
  end

  describe ".preload_candidate_counts" do
    let!(:developer) { create(:user, firstname: "Dev", lastname: "Eloper") }
    let!(:designer) { create(:user, firstname: "Des", lastname: "Igner") }

    let(:developers) { create(:placeholder_user, name: "Developers", user_filter: filters_for("name", "~", ["Eloper"])) }
    let(:designers) { create(:placeholder_user, name: "Designers", user_filter: filters_for("name", "~", ["Igner"])) }

    current_user { create(:admin) }

    it "resolves every resource's count in a single query" do
      resources = [developers, designers]

      recorder = ActiveRecord::QueryRecorder.new { described_class.preload_candidate_counts(resources) }

      expect(recorder.log.grep(/COUNT\(\*\)/).size).to eq(1)
      expect(resources.map(&:candidate_count)).to eq([1, 1])
    end

    it "counts against the project's members when one is given" do
      project = create(:project, members: { developer => create(:project_role) })
      resources = [developers, designers]

      described_class.preload_candidate_counts(resources, project:)

      expect(resources.map { |resource| resource.candidate_count(project:) }).to eq([1, 0])
    end

    it "leaves the preloaded counts in place for later reads" do
      described_class.preload_candidate_counts([developers])

      recorder = ActiveRecord::QueryRecorder.new { developers.candidate_count }

      expect(recorder.log).to be_empty
    end

    # A single unresolvable filter must not cost the whole list its counts.
    it "falls back to zero for a resource whose filter cannot be resolved" do
      allow(designers).to receive(:candidate_query).and_raise(StandardError, "broken filter")

      described_class.preload_candidate_counts([developers, designers])

      expect(developers.candidate_count).to eq(1)
      expect(designers.candidate_count).to eq(0)
    end
  end

  describe "as a principal" do
    current_user { create(:admin) }

    it "is not returned by scopes that select actual users" do
      expect(User.where(id: placeholder_user.id)).to be_empty
      expect(Principal.human.where(id: placeholder_user.id)).to be_empty
      expect(Principal.find(placeholder_user.id)).to eq(placeholder_user)
    end

    # UserQuery's default scope is User.user.visible, so a resource can never
    # match its own filter or another resource's.
    it "is not a candidate for any user filter" do
      placeholder_user.update!(user_filter: filters_for("name", "~", ["Senior"]))

      expect(placeholder_user.candidate_query.results).to be_empty
    end
  end
end
