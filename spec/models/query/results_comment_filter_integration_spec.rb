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

RSpec.describe Query::Results, "Comment filter integration", with_ee: %i[internal_comments] do
  let(:project) { create(:project, enabled_internal_comments: true) }
  let!(:public_comment_wp) { create(:work_package, project:) }
  let!(:internal_comment_wp) { create(:work_package, project:) }
  let(:query) { Query.new(user:, project:, include_subprojects: false) }

  subject(:work_packages) { described_class.new(query).work_packages }

  before do
    add_note(public_comment_wp, "a public note", internal: false)
    add_note(internal_comment_wp, "an internal note", internal: true)

    login_as(user)
  end

  def add_note(work_package, notes, internal:)
    work_package.add_journal(user: create(:admin), notes:, internal:)
    work_package.save!(validate: false)
  end

  describe "comment filter" do
    let(:operator) { "~" }

    before do
      query.add_filter("comment", operator, ["note"])
    end

    context "when the user is not allowed to see internal comments" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      it "does not match internal comments" do
        expect(work_packages).to contain_exactly(public_comment_wp)
      end
    end

    context "when the user is allowed to see internal comments" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages view_internal_comments] }) }

      it "matches internal comments" do
        expect(work_packages).to contain_exactly(public_comment_wp, internal_comment_wp)
      end
    end

    context "when the user is not allowed to see internal comments and filtering by does not contain" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
      let(:operator) { "!~" }

      it "treats work packages matching only in internal comments as not containing the text" do
        expect(work_packages).to contain_exactly(internal_comment_wp)
      end
    end
  end
end
