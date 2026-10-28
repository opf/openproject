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

module CertificateHelper
  module_function

  def private_key
    @private_key ||= OpenSSL::PKey::RSA.new(1024)
  end

  def non_padded_string(certificate_name)
    public_send(certificate_name)
      .to_pem
      .gsub("-----BEGIN CERTIFICATE-----", "")
      .gsub("-----END CERTIFICATE-----", "")
      .delete("\n")
      .strip
  end

  def valid_certificate
    @valid_certificate ||= begin
      name = OpenSSL::X509::Name.parse "/CN=valid-testing"
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1234

      cert.not_before = Time.current
      cert.not_after = Time.current + 606024364.251
      cert.public_key = private_key.public_key
      cert.subject = name
      cert.issuer = name
      cert.sign private_key, OpenSSL::Digest.new("SHA1")
    end
  end

  def expired_certificate
    @expired_certificate ||= begin
      name = OpenSSL::X509::Name.parse "/CN=expired-testing"
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1234

      cert.not_before = 2.years.ago
      cert.not_after = 30.days.ago
      cert.public_key = private_key.public_key
      cert.subject = name
      cert.issuer = name
      cert.sign private_key, OpenSSL::Digest.new("SHA1")
    end
  end

  def mismatched_certificate
    @mismatched_certificate ||= begin
      name = OpenSSL::X509::Name.parse "/CN=mismatched-testing"
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1234

      key = OpenSSL::PKey::RSA.new(1024)
      cert.not_before = Time.current
      cert.not_after = Time.current + 606024364.251
      cert.public_key = key.public_key
      cert.subject = name
      cert.issuer = name
      cert.sign key, OpenSSL::Digest.new("SHA1")
    end
  end
end
