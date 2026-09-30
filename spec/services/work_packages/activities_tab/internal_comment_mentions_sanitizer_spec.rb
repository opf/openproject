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

RSpec.describe WorkPackages::ActivitiesTab::InternalCommentMentionsSanitizer do
  include InternalCommentsHelpers

  shared_let(:project) { create(:project) }
  shared_let(:admin_but_non_member) { create(:admin) }
  shared_let(:viewer) { create_user_without_internal_comments_view_permissions }
  shared_let(:user_with_internal_comments_view_and_write_permissions) do
    create_user_with_internal_comments_view_and_write_permissions
  end
  shared_let(:non_mentionable_user) { create(:user) }
  shared_let(:project_admin) { create_user_as_project_admin }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:comment) do
    <<~HTML
      <mention class="mention" data-id="#{admin_but_non_member.id}" data-type="user" data-text="@#{admin_but_non_member.firstname}">@#{admin_but_non_member.firstname}</mention> wrote:

      > Well Done!

      <mention class="mention" data-id="#{viewer.id}" data-type="user" data-text="@#{viewer.firstname}">@#{viewer.firstname}</mention> wrote:

      > <mention class="mention" data-id="#{user_with_internal_comments_view_and_write_permissions.id}" data-type="user" data-text="@#{user_with_internal_comments_view_and_write_permissions.firstname}">@#{user_with_internal_comments_view_and_write_permissions.firstname}</mention> wrote:
      >
      > > <mention class="mention" data-id="#{project_admin.id}" data-type="user" data-text="@#{project_admin.firstname}">@#{project_admin.firstname}</mention> wrote:
      > >
      > > > FooBar
      > >
      > > <mention class="mention" data-id="#{non_mentionable_user.id}" data-type="user" data-text="@Firstname">@Firstname</mention> wrote:
      > >
      > > > BooBar
    HTML
  end

  let(:expected_sanitized_comment) do
    <<~HTML
      @#{admin_but_non_member.firstname} wrote:

      > Well Done!

      @#{viewer.firstname} wrote:

      > <mention class="mention" data-id="#{user_with_internal_comments_view_and_write_permissions.id}" data-type="user" data-text="@#{user_with_internal_comments_view_and_write_permissions.firstname}">@#{user_with_internal_comments_view_and_write_permissions.firstname}</mention> wrote:
      >
      > > <mention class="mention" data-id="#{project_admin.id}" data-type="user" data-text="@#{project_admin.firstname}">@#{project_admin.firstname}</mention> wrote:
      > >
      > > > FooBar
      > >
      > > @Firstname wrote:
      > >
      > > > BooBar
    HTML
  end

  subject { described_class.new(work_package, comment).call }

  before { allow(User).to receive(:current).and_return(user_with_internal_comments_view_and_write_permissions) }

  it "sanitizes the comment" do
    expect(subject).to eq(expected_sanitized_comment)
  end

  context "when the comment is empty" do
    let(:comment) { "" }

    it "returns an empty string" do
      expect(subject).to eq("")
    end
  end
end
