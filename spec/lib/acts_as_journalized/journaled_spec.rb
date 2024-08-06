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

RSpec.describe "Journalized Objects" do
  describe "journal_editable_by?" do
    context "when the journable is a work package" do
      let!(:user) { create(:user, member_with_permissions: { project => [] }) }
      let!(:project) { create(:project_with_types) }
      let!(:work_package) do
        create(:work_package,
               type: project.types.first,
               author: user,
               project:,
               description: "")
      end

      subject { work_package.journal_editable_by?(work_package.journals.first, user) }

      context 'and the user has no permission to "edit_work_packages"' do
        it { is_expected.to be_falsey }
      end
    end
  end
end
