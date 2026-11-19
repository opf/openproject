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
  describe ".encrypt_text" do
    it "encodes long encrypted values without line breaks" do
      encrypted = described_class.encrypt_text("x" * 40)

      expect(encrypted).not_to include("\n")
    end
  end

  describe ".decrypt_text" do
    it "decrypts long encrypted values" do
      plaintext = "x" * 40

      expect(described_class.decrypt_text(described_class.encrypt_text(plaintext))).to eq(plaintext)
    end

    it "decrypts values stored with line-wrapped Base64 encoding" do
      plaintext = "x" * 40
      encrypted = described_class.encrypt_text(plaintext)
      legacy_encrypted = encrypted.sub(/\A(aes-256-cbc:.{60})/, "\\1\n")

      expect(described_class.decrypt_text(legacy_encrypted)).to eq(plaintext)
    end
  end
end
