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

class Header::WhatsNewController < ApplicationController
  include OpTurbo::ComponentStream

  no_authorization_required! :show, :dialog, :seen, :read

  before_action :require_visible_release

  def show
    render Header::WhatsNewComponent.new(release:), layout: false
  end

  def dialog
    respond_with_dialog Header::WhatsNewDialogComponent.new(release:)
  end

  def seen
    current_user.pref.mark_whats_new_seen(release.version_key)
    current_user.pref.save!

    turbo_streams << turbo_stream.remove_all("[data-whats-new-badge]")
    respond_with_turbo_streams
  end

  def read
    key = params.expect(:key)
    return head :unprocessable_entity unless release.item?(key)

    mark_read(key)

    turbo_streams << turbo_stream.remove_all("[data-whats-new-dot='#{key}']")
    respond_with_turbo_streams
  end

  private

  def mark_read(key)
    current_user.pref.mark_whats_new_read(release.version_key, key)
    current_user.pref.save!
  end

  def release
    @release ||= WhatsNew::Release.current
  end

  def require_visible_release
    render_404 unless release.visible_to?(current_user)
  end
end
