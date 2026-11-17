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

RSpec.shared_examples "an encrypted credential" do |attribute|
  def stored_credential(attribute)
    credential_record.reload.read_attribute_before_type_cast(attribute)
  end

  it "persists credentials with Active Record encryption" do
    credential_record.update!(attribute => "new-password")

    expect(stored_credential(attribute)).to start_with('{"p":')
    expect(credential_record.public_send(attribute)).to eq("new-password")
  end

  it "round trips nil, empty and whitespace credentials" do
    [nil, "", " "].each do |value|
      credential_record.update!(attribute => value)
      expect(credential_record.reload.public_send(attribute)).to eq(value)
    end
  end

  it "round trips the maximum length unicode credential" do
    password = "🔑" * 255
    credential_record.update!(attribute => password)

    expect(credential_record.reload.public_send(attribute)).to eq(password)
  end

  it "rejects credentials exceeding the plaintext length limit" do
    credential_record.public_send(:"#{attribute}=", "x" * 256)

    credential_record.valid?

    expect(credential_record.errors.of_kind?(attribute, :too_long)).to be true
  end

  it "rejects a modified stored credential" do
    credential_record.update!(attribute => "password")
    message = JSON.parse(stored_credential(attribute))
    message["p"][0] = message["p"][0] == "A" ? "B" : "A"
    ActiveRecord::Encryption.without_encryption do
      credential_record.update_columns(attribute => JSON.generate(message))
    end

    expect { credential_record.reload.public_send(attribute) }
      .to raise_error(ActiveRecord::Encryption::Errors::Decryption)
  end
end
