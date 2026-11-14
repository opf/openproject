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

require "spec_helper"

RSpec.describe Redmine::Ciphering, with_config: { "database_cipher_key" => "secret" } do
  describe ".decrypt_text" do
    it "decrypts legacy encrypted values" do
      expect(described_class.decrypt_text("aes-256-cbc:w8ptVp+/egSM1uKWSLw4CA==--MDEyMzQ1Njc4OWFiY2RlZg=="))
        .to eq("legacy-password")
    end

    it "decrypts values stored with line-wrapped Base64 encoding" do
      expect(described_class.decrypt_text("aes-256-cbc:w8ptVp+/egSM1uKWSLw\n4CA==--MDEyMzQ1Njc4OWFiY2RlZg=="))
        .to eq("legacy-password")
    end

    it "returns plaintext values unchanged" do
      expect(described_class.decrypt_text("plaintext")).to eq("plaintext")
    end
  end
end
