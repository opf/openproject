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

RSpec.describe Sessions::UserSession do
  subject { described_class.new session_id: "foo" }

  describe "#save" do
    it "can not save" do
      expect { subject.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { subject.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe "#update" do
    let(:session) { create(:user_session) }

    subject { described_class.find_by(session_id: session.session_id) }

    it "can not update" do
      expect { subject.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { subject.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)

      expect { subject.update(session_id: "foo") }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { subject.update!(session_id: "foo") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe "#destroy" do
    let(:sessions) { create(:user_session) }

    it "can not destroy" do
      expect { subject.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { subject.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe ".for_user" do
    let(:user) { create(:user) }
    let!(:sessions) { create_list(:user_session, 2, user:) }

    subject { described_class.for_user(user) }

    it "can find and delete, but not destroy those sessions" do
      expect(subject.pluck(:session_id)).to match_array(sessions.map(&:session_id))

      expect { subject.destroy_all }.to raise_error(ActiveRecord::ReadOnlyRecord)

      expect { subject.delete_all }.not_to raise_error

      expect(described_class.for_user(user).count).to eq 0
    end
  end

  describe ".non_user" do
    let!(:session) { create(:user_session, user: nil) }

    subject { described_class.non_user }

    it "can find those sessions" do
      expect(subject.pluck(:session_id)).to contain_exactly(session.session_id)
    end
  end
end
