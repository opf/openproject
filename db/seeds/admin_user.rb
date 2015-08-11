#-- encoding: UTF-8
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

if User.admin.empty?
  user = User.new

  user.admin = true
  user.login = 'admin'
  user.password = '!AdminAdminAdmin123%&/'
  user.firstname = 'OpenProject'
  user.lastname = 'Admin'
  user.mail = ENV.fetch('ADMIN_EMAIL') { 'admin@example.net' }
  user.mail_notification = User::USER_MAIL_OPTION_NON.first
  user.language = I18n.locale.to_s
  user.status = User::STATUSES[:active]
  user.save!

  # Enable the user to login easily but force him
  # to change his password right away unless we are
  # only seeding the development database.
  user.force_password_change = Rails.env != 'development'
  user.password = 'admin'
  user.save(validate: false)
end
