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

RSpec.describe PushSubscription do
  let(:user) { create(:user) }
  let!(:subscription) { create(:push_subscription, user:) }

  it "becomes dormant when its session is deleted" do
    Sessions::UserSession.where(id: subscription.session_id).delete_all

    expect(subscription.reload.session_id).to be_nil
    expect(described_class.dormant).to contain_exactly(subscription)
    expect(described_class.active).to be_empty
  end

  it "is removed when its user is destroyed" do
    expect { user.destroy }
      .to change { described_class.exists?(subscription.id) }.from(true).to(false)
  end

  it "is removed when its user is locked" do
    user.lock
    expect { user.save! }
      .to change { described_class.exists?(subscription.id) }.from(true).to(false)
  end

  it "is kept when an unrelated user is registered locked" do
    expect { create(:user, status: Principal.statuses[:locked]) }
      .not_to change { described_class.exists?(subscription.id) }.from(true)
  end

  it "is kept when its active user is saved without a status change" do
    expect { user.update!(firstname: "Renamed") }
      .not_to change { described_class.exists?(subscription.id) }.from(true)
  end

  describe ".under_host" do
    let!(:apple) { create(:push_subscription, endpoint: "https://web.push.apple.com/abc") }
    let!(:windows) { create(:push_subscription, endpoint: "https://wns2-db5p.notify.windows.com/w/?token=abc") }
    let!(:lookalike) { create(:push_subscription, endpoint: "https://notify.windows.com.evil.example/w") }

    it "matches the host itself and its subdomains, but not a look-alike suffix" do
      expect(described_class.under_host("push.apple.com")).to contain_exactly(apple)
      expect(described_class.under_host("notify.windows.com")).to contain_exactly(windows)
      expect(described_class.under_host("fcm.googleapis.com")).to contain_exactly(subscription)
      expect(described_class.under_host("evil.example")).to contain_exactly(lookalike)
    end
  end

  it "requires a unique endpoint" do
    duplicate = build(:push_subscription, user:, endpoint: subscription.endpoint)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors).to be_added(:endpoint, :taken, value: subscription.endpoint)
  end

  it "allows only one subscription per session at the database level" do
    expect { create(:push_subscription, user:, session: subscription.session) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
