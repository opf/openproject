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

RSpec.describe Meetings::CreateService, "integration", type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i(view_meetings create_meetings) })
  end
  shared_let(:other_user) do
    create(:user, member_with_permissions: { project => %i(view_meetings) })
  end
  let(:instance) { described_class.new(user:) }
  let(:service_result) { subject }
  let(:series) { service_result.result }
  let(:params) { {} }
  let(:default_params) do
    {
      project:,
      title: "My test meeting"
    }
  end

  subject { instance.call(**params, **default_params) }

  describe "project" do
    context "when not provided" do
      let(:default_params) { { title: "foo" } }

      it "complains about the project, not the base authorization" do
        expect(subject).not_to be_success
        expect(subject.errors[:base]).to be_empty
        expect(subject.errors[:project_id]).to contain_exactly "can't be blank."
      end
    end
  end

  describe "backlog" do
    it "creates a backlog" do
      expect(subject).to be_success
      expect(subject.result.backlog).to be_present
    end
  end

  describe "participants" do
    context "when passed" do
      let(:params) do
        {
          participants_attributes: [
            { user_id: other_user.id, invited: true, attended: true }
          ]
        }
      end

      it "creates that meeting with that one participant" do
        expect(subject).to be_success
        expect(subject.result.participants.count).to eq(1)
        expect(subject.result.participants.first.user).to eq(other_user)
      end
    end

    context "when passed as empty" do
      let(:params) do
        {
          participants_attributes: {}
        }
      end

      it "creates the meeting with default" do
        expect(subject).to be_success
        expect(subject.result.participants.count).to eq(1)
        expect(subject.result.participants.first.user).to eq(user)
      end
    end

    context "when not passed" do
      it "creates the meeting with default" do
        expect(subject).to be_success
        expect(subject.result.participants.count).to eq(1)
        expect(subject.result.participants.first.user).to eq(user)
      end
    end
  end

  describe "sharing" do
    context "when creating a regular meeting" do
      it "does not set sharing" do
        expect(subject).to be_success
        expect(subject.result.sharing).to be_nil
      end
    end

    context "when creating an onetime template" do
      let(:default_params) { { project:, title: "My template", template: true } }

      it "sets sharing to none by default" do
        expect(subject).to be_success
        expect(subject.result.sharing).to eq("none")
      end
    end
  end
end
