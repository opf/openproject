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

RSpec.describe Attachments::CleanupUncontaineredJob, type: :job do
  let(:grace_period) { 120 }

  let!(:containered_attachment) { create(:attachment) }
  let!(:old_uncontainered_attachment) do
    create(:attachment, container: nil, created_at: Time.now - grace_period.minutes)
  end
  let!(:new_uncontainered_attachment) do
    create(:attachment, container: nil, created_at: Time.now - (grace_period - 1).minutes)
  end

  let!(:finished_upload) do
    create(:attachment, created_at: Time.now - grace_period.minutes, status: :uploaded)
  end
  let!(:old_pending_upload) do
    create(:attachment, created_at: Time.now - grace_period.minutes, status: :prepared)
  end
  let!(:new_pending_upload) do
    create(:attachment, created_at: Time.now - (grace_period - 1).minutes, status: :prepared)
  end

  let(:job) { described_class.new }

  before do
    allow(OpenProject::Configuration)
      .to receive(:attachments_grace_period)
      .and_return(grace_period)
  end

  it "removes all uncontainered attachments and pending uploads that are older than the grace period" do
    job.perform

    expect(Attachment.all)
      .to contain_exactly(containered_attachment, new_uncontainered_attachment, finished_upload, new_pending_upload)
  end
end
