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

RSpec.describe Queries::News::NewsQuery do
  let(:instance) { described_class.new }

  shared_let(:role) { create(:project_role, permissions: [:view_news]) }
  shared_let(:project) { create(:project) }
  shared_let(:visible_news) { create(:news, project:) }
  shared_let(:other_project)  { create(:project) }
  shared_let(:other_visible_news) { create(:news, project: other_project) }
  shared_let(:invisible_news) { create(:news) }

  current_user do
    create(:user,
           member_with_roles: {
             project => [role],
             other_project => [role]
           })
  end

  context "without a filter" do
    describe "#results" do
      it "is the same as getting all the visible news" do
        expect(instance.results)
          .to eq [other_visible_news, visible_news]
      end
    end
  end

  context "with a project filter" do
    before do
      instance.where("project_id", "=", [project.id])
    end

    describe "#results" do
      it "returns the news from the project" do
        expect(instance.results)
          .to contain_exactly(visible_news)
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("project_id", "=", [""])
        expect(instance).to be_invalid
      end
    end
  end

  context "with an order by id asc" do
    describe "#results" do
      it "returns all visible news ordered by id asc" do
        expect(instance.order(id: :asc).results)
          .to eq [visible_news, other_visible_news]
      end
    end
  end
end
