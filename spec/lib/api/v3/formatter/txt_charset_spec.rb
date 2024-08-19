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

RSpec.describe API::V3::Formatter::TxtCharset do
  let(:umlaut_object_ascii) { "ümläutß".force_encoding("ASCII-8BIT") }
  let(:umlaut_object_utf8) { umlaut_object_ascii.force_encoding("utf-8") }
  let(:env) { {} }

  describe "#call" do
    it "returns the object (string) encoded in the charset defined in env" do
      env["CONTENT_TYPE"] = "text/plain; charset=UTF-8"

      expect(described_class.call(umlaut_object_ascii.dup, env)).to eql umlaut_object_utf8
    end

    it "returns the object (string) in default encoding if nothing defined in env" do
      expect(described_class.call(umlaut_object_ascii.dup, env)).to eql umlaut_object_utf8
    end

    it "returns the object (string) unchanged if invalid charset is provided in env" do
      env["CONTENT_TYPE"] = "text/plain; charset=bogus"

      expect(described_class.call(umlaut_object_ascii.dup, env)).to eql umlaut_object_ascii
    end
  end
end
