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

require "support/shared/acts_as_watchable"

RSpec.describe Forum do
  it_behaves_like "acts_as_watchable included" do
    let(:model_instance) { create(:forum) }
    let(:watch_permission) { :view_messages } # view_messages is a public permission
    let(:project) { model_instance.project }
  end

  describe "with forum present" do
    let(:forum) { build(:forum, name: "Test forum", description: "Whatever") }

    it "creates" do
      expect(forum.save).to be_truthy
      forum.reload
      expect(forum.name).to eq "Test forum"
      expect(forum.description).to eq "Whatever"
      expect(forum.topics_count).to eq 0
      expect(forum.messages_count).to eq 0
      expect(forum.last_message).to be_nil
    end
  end
end
