#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

##
# LEGACY password hashing method using salted SHA-1
# This is only included for testing hashed passwords and will raise when trying
# to save new passwords with that strategy.
class UserPassword::SHA1 < UserPassword
  protected

  ##
  # Determines whether the hashed value of +plain+ matches the stored password hash.
  def hash_matches?(plain)
    test_hash = derive_password!(plain)
    secure_equals?(test_hash, hashed_password)
  end

  # constant-time comparison algorithm to prevent timing attacks
  def secure_equals?(a, b)
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize
    l = a.unpack "C#{a.bytesize}"

    res = 0
    b.each_byte do |byte| res |= byte ^ l.shift end
    res == 0
  end

  ##
  # Override the base method to disallow new passwords being generated this way.
  def salt_and_hash_password!
    raise ArgumentError, 'Do not use UserPassword::SHA1 for new passwords!'
  end

  ##
  # Hash a plaintext password with a given salt
  # The hashed password has following form: SHA1(salt + SHA1(password))
  def derive_password!(input)
    hashfn("#{salt}#{hashfn(input)}")
  end

  def hashfn(input)
    Digest::SHA1.hexdigest(input)
  end
end
