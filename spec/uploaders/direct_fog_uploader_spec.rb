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

RSpec.describe DirectFogUploader do
  describe ".direct_fog_hash" do
    let(:attachment) do
      Attachment.new(id: 42, content_type: "image/png").tap do |attachment|
        attachment[:file] = "cat.png"
      end
    end
    let(:policy) { JSON.parse(Base64.decode64(described_class.direct_fog_hash(attachment:)[:policy])) }
    let(:expiration) { Time.zone.parse(policy["expiration"]) }

    it "expires after four hours by default" do
      expect(expiration).to be_within(1.minute).of(4.hours.from_now)
    end

    context "with a configured expiration", with_config: { fog_direct_upload_expires_in: 600 } do
      it "expires after the configured time" do
        expect(expiration).to be_within(1.minute).of(10.minutes.from_now)
      end
    end
  end
end
