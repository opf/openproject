#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# Filter for all work packages that are (or are not) predecessor of the provided values

class Queries::WorkPackages::Filter::PrecedesFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  include ::Queries::WorkPackages::Filter::FilterOnDirectedRelationsMixin

  def relation_type
    ::Relation::TYPE_PRECEDES
  end

  private

  def relation_filter
    { from_id: values }
  end

  def relation_select
    :to_id
  end
end

{
  "providers" => {
    "saml" => {
      "name" => "saml",
      "display_name" => "GEI SSO",
      "email" => "email",
      "login" => "username",
      "first_name" => "firstname",
      "last_name" => "lastname",
      "assertion_consumer_service_url" => "https://pm-test.intern.gei.de/auth/saml/callback",
      "idp_cert_fingerprint" => "A6:05:F5:02:88:36:20:BA:76:C7:B0:F0:EE:DD:38:F7:EC:13:DE:38",
      "idp_sso_target_url" => "https://idp-test.gei.de/idp/profile/SAML2/Redirect/SSO",
      "idp_slo_target_url" => "https://idp-test.gei.de/idp/profile/SAML2/Redirect/SLO",
      "certificate" => '-----BEGIN\nCERTIFICATE-----\nMIIEETCCAnmgAwIBAgIUa69lX7LqrAGmli9dnraSuBk4YxAwDQYJKoZIhvcNAQEL\nBQAwIDEeMBwGA1UEAxMVcG0tdGVzdC5pbnRlcm4uZ2VpLmRlMB4XD
TIyMDUxODE0\nMDMwNloXDTMyMDUxNTE0MDMwNlowIDEeMBwGA1UEAxMVcG0tdGVzdC5pbnRlcm4u\nZ2VpLmRlMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA0EpMgCk5FSqg\n2sOS5iU2v6OGU1hbupclj293HkN4UzISbXvBaYY/MFGDU
BIDLHwXlRGXjWytPgwh\ngDma8W9foFc0Wa/JpH+DPfkj4c3ltK2WqEoMuSy7Zf/LTQW+xNqb6wLbDW102Buv\nr6dQBfMgYfr4HSm4ZxP3VIytf2IEqPzCJF4Tzwn8FC9SkT0UU6zGak89qSKDFdiU\nDPehTDbaOExElJicXGR4lxCYiZ/TLpChdUArG
RYf+5Y73NgvrzO0I5iGmIvmBhAY\nqchfoE+K0I4z+xFhjULIEHnwZfAA1ovCkfGZLJUZVf5achDqLswMN3HBwiGk/T+U\nKyPtiasgCzkjSI/+smwdgQ0cVbqB3cHRpCDwE7XNx8swO7oFWWLVGEZNDwPtaNY5\nGY6p+8foD5CrF6t4mCZdzhZ6exoi1
uoP5+IUuctwLnyLAaOeCGX/fLrUCd6D/IGB\nnOdVMerHXUpxJFESREVQj0RbWtNDxMTjsGLLPn6PCh0zbnQ/W6BjAgMBAAGjQzBB\nMCAGA1UdEQQZMBeCFXBtLXRlc3QuaW50ZXJuLmdlaS5kZTAdBgNVHQ4EFgQUWTeT\n1KNagMAf5vstHkNac2XlF
XAwDQYJKoZIhvcNAQELBQADggGBAAZ/wL3Q0LK5v/El\njGySQPf7UYFv0a3jSPFELGrrM+DrhdVCmpvEq/G+5+mmPa392/maBj906AHLWC/n\nEqSi9CG4Y2EDkFHXKbqg9esZSgXK5A9knvsj0t3BHRZEev00Ij9h2z7cIWmNDK3J\nyQwuzUry5JA69
8zXt9Oib+90bpp3QyAYg7bnN830RwdCA7Hcp6wA5KxOCi1LNzzs\nAuME+FN7Co+sIqXp5a39oHJchAz7ryLFuSIH19ZStdJzc5ujiXpmbPd+oW5Ccwp5\n9jUqpbMmh1E05odcXIJL1OfRsyd11YT3MG/ERA9QtVesRA5kiQjWPPHi8OeUp/Cn\n0/XCv
0qt5IZkQOt+7c0mOlN1GeLGUB5mOt28A5UUKOee+kusiB6h3ir4DF3s4DL8\nZJpm8UChwDkMzwcA8TKBCsoFuu1tloCJ7nh1ulLxmn5AH4nZDxIc+WDG1Gqb4OW7\nGfinIWEkqXPzuv2h1Lq1j0Ll9Z7qJZqFeoDWYb3SVDrTUUrvag==\n-----END\
nCERTIFICATE-----',
      "private_key" => 'test',
      "security" => {
        "authn_requests_signed" => "true",
        "want_assertions_signed" => "true",
        "embed_sign" => "true",
        "signature_method" => ' http : // www.w3.org / 2001 / 04 / xmldsig - more #rsa-sha256',
        "digest_method" => 'http://www.w3.org/2001/04/xmlenc#sha256',
      }
    }
  }
}
