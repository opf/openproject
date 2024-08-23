# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "spec_helper"

RSpec.describe Queries::Queries::QueryQuery do
  let(:instance) { described_class.new(user:) }

  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages]
           })
  end
  shared_let(:other_user) { create(:user) }
  shared_let(:global_query) { create(:query, user:, project: nil) }
  shared_let(:project_query) { create(:query, user:, project:) }
  shared_let(:other_user_project_query) { create(:query, user: other_user, project:) }
  shared_let(:other_user_public_project_query) { create(:query, user: other_user, project:, public: true) }

  current_user { user }

  describe "#results" do
    subject { instance.results }

    context "without a filter" do
      it "returns all visible filters" do
        expect(subject).to eq [other_user_public_project_query, project_query, global_query]
      end
    end

    context "with an updated_at filter" do
      before do
        other_user_public_project_query.update_column(:updated_at, "2018-03-22 10:00:00")

        instance.where("updated_at", "<>d", ["2018-03-21 22:00:00", "2018-03-22 22:00:00"])
      end

      it "returns the query updated between the timestamps" do
        expect(subject).to eq [other_user_public_project_query]
      end
    end

    context "with a project filter" do
      before do
        instance.where("project_id", "=", [project.id.to_s])
      end

      it "returns the queries inside that project" do
        expect(subject).to eq [other_user_public_project_query, project_query]
      end
    end
  end
end
