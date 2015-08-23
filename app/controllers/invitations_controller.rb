#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'uri'

class InvitationsController < ApplicationController

  skip_before_filter :check_if_login_required, only: [:claim]

  def index

  end

  def create
    email = params.require(:email)
    user = User.create mail: email, login: email, firstname: email, lastname: email
    token = invite_user user

    if user.errors.empty?
      first, last = email.split("@")
      user.firstname = first
      user.lastname = "@#{last}"
      user.invite

      user.save!
      token.save!

      puts
      puts "CREATED NEW TOKEN: #{token.value}"
      puts

      redirect_to action: :show, id: user.id
    else
      flash.now[:error] = user.errors.full_messages.first

      render 'index', locals: { email: email }
    end
  end

  def show
    user = User.find params.require(:id)
    token = Token.find_by action: token_action, user: user

    render 'show', locals: { token: token.value, email: user.mail }
  end

  def claim
    token = Token.find_by action: token_action, value: params.require(:id)

    if current_user.logged?
      flash[:warning] = 'You are already registered, mate.'

      redirect_to invitation_path id: token.user_id
    else
      session[:invitation_token] = token.value
      flash[:info] = 'Create a new account or register now, pl0x!'

      redirect_to signin_path
    end
  end

  module Functions
    def token_action
      'invitation'
    end

    def invite_user(user)
      token = invitation_token user

      token
    end

    def invitation_token(user)
      Token.find_or_initialize_by user: user, action: token_action
    end
  end

  include Functions
end
