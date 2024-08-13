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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Queries::ICalSharingContract do
  include_context "ModelContract shared context"

  # using `create` approach here as many underlying checks base on
  # real database checks which should not be mocked

  let(:project) { create(:project) }
  let(:public) { false }
  let(:user) { current_user }
  let(:permissions) { %i() }
  let(:query) do
    create(:query, project:, public:, user:)
  end
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:ical_token) { create(:ical_token, user: current_user, query:, name: "Some Token") }

  # override as this contract additionally needs the ical_token
  let(:contract) { described_class.new(query, current_user, options: { ical_token: }) }

  describe "private query" do
    let(:public) { false }

    context "when user is author", with_settings: { ical_enabled: true } do
      let(:user) { current_user }

      context "when user has no permission to share via ical" do
        let(:permissions) { %i(view_work_packages view_calendar manage_calendars) }

        it_behaves_like "contract user is unauthorized"
      end

      context "when user has permission to share via" do
        let(:permissions) { %i(view_work_packages share_calendars) }

        it_behaves_like "contract is valid"

        context "when iCalendar subscriptions are globally disabled", with_settings: { ical_enabled: false } do
          it_behaves_like "contract user is unauthorized"
        end
      end

      context "when ical_token is not scoped to query" do
        let(:other_query) do
          create(:query, project:, public:, user:)
        end
        let(:ical_token) { create(:ical_token, query: other_query, user: current_user, name: "Some Token") }

        context "when user has no permission to share via ical" do
          let(:permissions) { %i(view_work_packages view_calendar manage_calendars) }

          it_behaves_like "contract user is unauthorized"
        end

        context "when user has permission to share via ical" do
          let(:permissions) { %i(view_work_packages share_calendars) }

          it_behaves_like "contract user is unauthorized"
        end
      end
    end

    context "when author is someone else", with_settings: { ical_enabled: true } do
      let(:user) { create(:user) } # other user as owner of query
      let(:permissions) { %i(view_work_packages share_calendars) } # all necessary permissions

      it_behaves_like "contract user is unauthorized" # unauthorized as user is not author
    end
  end

  describe "public query" do
    let(:public) { true }
    let(:user) { current_user }

    context "when user has no permission to share via ical", with_settings: { ical_enabled: true } do
      let(:permissions) { %i(view_work_packages view_calendar manage_calendars) }

      it_behaves_like "contract user is unauthorized"

      context "when author is someone else" do
        let(:user) { create(:user) } # other user as owner of query

        it_behaves_like "contract user is unauthorized" # authorized as query is public
      end
    end

    context "when user has permission to share via ical", with_settings: { ical_enabled: true } do
      let(:permissions) { %i(view_work_packages share_calendars) }

      it_behaves_like "contract is valid"

      context "when author is someone else" do
        let(:user) { create(:user) } # other user as owner of query

        it_behaves_like "contract is valid" # authorized as query is public
      end

      context "when iCalendar subscriptions are globally disabled", with_settings: { ical_enabled: false } do
        it_behaves_like "contract user is unauthorized"

        context "when author is someone else" do
          let(:user) { create(:user) } # other user as owner of query

          it_behaves_like "contract user is unauthorized"
        end
      end
    end
  end

  describe "project membership" do
    let(:public) { false }
    let(:other_project) { create(:project) }
    let(:current_user) do
      create(:user,
             member_with_permissions: { other_project => permissions })
    end

    context "when user is author but not member of project (anymore)", with_settings: { ical_enabled: true } do
      let(:user) { current_user }

      context "when user has no permission to share via ical" do
        let(:permissions) { %i(view_work_packages view_calendar manage_calendars) }

        it_behaves_like "contract user is unauthorized"
      end
    end
  end

  include_examples "contract reuses the model errors"
end
