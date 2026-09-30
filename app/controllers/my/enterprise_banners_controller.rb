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
class My::EnterpriseBannersController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :require_login
  before_action :get_feature_key

  authorization_checked! :dismiss, :show

  def show
    dismissable = ActiveRecord::Type::Boolean.new.cast(params[:dismissable])

    respond_to do |format|
      format.html do
        render(EnterpriseEdition::BannerComponent.new(@feature_key, dismissable:), layout: false)
      end
    end
  end

  def dismiss
    pref = User.current.pref
    pref.dismiss_banner(@dismiss_key)
    if pref.save
      remove_via_turbo_stream(component: EnterpriseEdition::BannerComponent.new(
        @feature_key,
        dismiss_key: @dismiss_key,
        show_always: true
      ))
      respond_with_turbo_streams
    else
      respond_with_flash_error(message: call.message)
    end
  end

  private

  def get_feature_key
    @feature_key = params[:feature_key].to_sym
    @dismiss_key = params[:dismiss_key].presence&.to_sym || @feature_key

    render_400 unless OpenProject::Token.lowest_plan_for(@feature_key)
  end
end
