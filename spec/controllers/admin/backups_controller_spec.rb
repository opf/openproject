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

RSpec.describe Admin::BackupsController, with_config: { backup_enabled: true } do
  let(:user) { create(:user, global_permissions: [:create_backup]) }

  current_user { user }

  describe "#delete_token" do
    let!(:backup_token) { create(:backup_token, user:) }
    let(:backup) { create(:backup) }
    let!(:job_status) { create(:delayed_job_status, user:, reference: backup) }
    let!(:attachment) { create(:attachment, container: backup) }

    it "destroys the backup token" do
      expect { delete :delete_token }
        .to change { Token::Backup.where(user:).count }.from(1).to(0)
    end

    it "destroys backup records belonging to the user" do
      expect { delete :delete_token }
        .to change { Backup.joins(:job_status).where(job_status: { user: }).count }.from(1).to(0)
    end

    it "destroys backup attachments belonging to the user" do
      expect { delete :delete_token }
        .to change { Attachment.where(container: backup).count }.from(1).to(0)
    end

    context "when another user also has a backup" do
      let(:other_user) { create(:user, global_permissions: [:create_backup]) }
      let(:other_backup) { create(:backup) }
      let!(:other_job_status) { create(:delayed_job_status, user: other_user, reference: other_backup) }

      it "does not destroy other users' backups" do
        expect { delete :delete_token }
          .not_to change { Backup.joins(:job_status).where(job_status: { user: other_user }).count }
      end
    end
  end
end
