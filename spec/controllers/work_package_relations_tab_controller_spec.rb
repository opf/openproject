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

RSpec.describe WorkPackageRelationsTabController do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:related_work_package) { create(:work_package, project:) }
  shared_let(:relations) do
    create_list(:relation,
                1,
                from: work_package,
                to: related_work_package,
                relation_type: Relation::TYPE_RELATES)
  end
  shared_let(:children) do
    create_list(:work_package, 2, parent: work_package, project:)
  end

  current_user { user }

  describe "GET /work_packages/:work_package_id/relations_tab" do
    before do
      allow(WorkPackageRelationsTab::IndexComponent).to receive(:new).and_call_original
    end

    it "renders the relations tab" do
      get("index", params: { work_package_id: work_package.id }, as: :turbo_stream)
      expect(WorkPackageRelationsTab::IndexComponent)
        .to have_received(:new).with(work_package:)

      expect(response).to be_successful
    end
  end
end
