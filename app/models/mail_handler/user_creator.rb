#  OpenProject is an open source project management software.
#  Copyright (C) 2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

class MailHandler::UserCreator
  class << self
    # Creates a user account for the +email+ sender
    def create_user_from_email(email)
      addr, name = extract_addr_and_name_from_email(email)

      if addr.present?
        user = new_user_from_attributes(addr, name)
        password = user.password

        if user.save
          [user, password]
        else
          logger.error "failed to create User: #{user.errors.full_messages}"
          nil
        end
      else
        logger.error 'failed to create User: no FROM address found'
        nil
      end
    end

    private

    # Returns a User from an email address and a full name
    def new_user_from_attributes(email_address, fullname = nil)
      call = Users::SetAttributesService
               .new(user: User.system, model: User.new, contract_class: Users::CreateContract)
               .call(**user_initialization_attributes(email_address, fullname))

      user = call.result

      user.random_password!

      assign_fallback_attributes(user, call.errors)

      user
    end

    def user_initialization_attributes(email_address, fullname = nil)
      names = fullname.blank? ? email_address.gsub(/@.*\z/, '').split('.') : fullname.split
      firstname = names.shift
      lastname = names.join(' ')
      lastname = '-' if lastname.blank?

      {
        mail: email_address,
        login: email_address,
        firstname:,
        lastname:
      }
    end

    def assign_fallback_attributes(user, errors)
      if errors.any?
        user.login = "user#{SecureRandom.hex(6)}" if errors[:login].present?
        user.firstname = '-' if errors[:firstname].present?
        user.lastname = '-' if errors[:lastname].present?
      end
    end

    def extract_addr_and_name_from_email(email)
      from = email.header['from'].to_s
      addr = from
      name = nil
      if m = from.match(/\A"?(.+?)"?\s+<(.+@.+)>\z/)
        addr = m[2]
        name = m[1]
      end

      [addr, name]
    end
  end
end
