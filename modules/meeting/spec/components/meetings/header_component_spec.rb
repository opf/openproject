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

require "rails_helper"

RSpec.describe Meetings::HeaderComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:meeting) { build_stubbed(:meeting, project:) }
  let(:user) { build_stubbed(:user) }

  subject do
    render_inline(described_class.new(meeting:, project:))
    page
  end

  before do
    login_as(user)
  end

  describe "send mail invitation" do
    context "when allowed" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:send_meeting_agendas_notification, project:)
        end
      end

      context "when open" do
        let(:meeting) { build_stubbed(:meeting, project:, state: :open) }

        it "renders the mail invitation" do
          expect(subject).to have_text I18n.t("meeting.label_mail_all_participants")
        end
      end

      context "when closed" do
        let(:meeting) { build_stubbed(:meeting, project:, state: :closed) }

        it "does not render the mail invitation" do
          expect(subject).to have_no_text I18n.t("meeting.label_mail_all_participants")
        end
      end
    end

    context "when not allowed" do
      let(:meeting) { build_stubbed(:meeting, project:, state: :open) }

      it "does not render the mail invitation" do
        expect(subject).to have_no_text I18n.t("meeting.label_mail_all_participants")
      end
    end
  end
end
