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

RSpec.describe Queries::Documents::DocumentQuery do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_documents],
             other_project => %i[view_documents]
           })
  end
  shared_let(:document) { create(:document, project:) }
  shared_let(:other_project_document) { create(:document, project: other_project) }
  shared_let(:invisible_document) { create(:document) }

  let(:instance) { described_class.new }

  current_user { user }

  describe "#results" do
    subject { instance.results }

    context "without a filter" do
      it "is the same as getting all the visible documents (ordered by id asc)" do
        expect(subject).to eq [other_project_document, document]
      end
    end

    context "with a project filter" do
      before do
        instance.where("project_id", "=", [project.id])
      end

      it "returns the documents in the filtered for project" do
        expect(subject).to eq [document]
      end
    end
  end
end
