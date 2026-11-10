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
require "open3"

RSpec.describe OpenProject::DatabaseEncryption do
  before do
    allow(Rails.application).to receive(:secret_key_base).and_return("secret-key-base")
  end

  describe ".primary_keys" do
    it "uses SECRET_KEY_BASE without an explicit key" do
      expect(described_class.primary_keys).to eq(["secret-key-base"])
    end

    context "with an explicit key", with_config: { "database_encryption_key" => "explicit" } do
      it "keeps SECRET_KEY_BASE for decryption and encrypts with the explicit key" do
        expect(described_class.primary_keys).to eq(%w[secret-key-base explicit])
      end
    end

    context "with a previous key", with_config: { "database_encryption_previous_key" => "previous" } do
      it "puts the previous key first" do
        expect(described_class.primary_keys).to eq(%w[previous secret-key-base])
      end
    end

    context "with a previous key equal to the explicit key",
            with_config: { "database_encryption_key" => "explicit", "database_encryption_previous_key" => "explicit" } do
      it "keeps the explicit key last" do
        expect(described_class.primary_keys.last).to eq("explicit")
      end
    end

    context "with blank keys", with_config: { "database_encryption_key" => "", "database_encryption_previous_key" => "" } do
      it "drops them" do
        expect(described_class.primary_keys).to eq(["secret-key-base"])
      end
    end
  end

  describe ".validate_secret!" do
    context "in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "raises for a shipped default secret" do
        allow(Rails.application).to receive(:secret_key_base).and_return("OVERWRITE_ME")

        expect { described_class.validate_secret! }.to raise_error(ArgumentError)
      end

      it "passes for a strong secret" do
        expect { described_class.validate_secret! }.not_to raise_error
      end

      context "with a strong explicit key", with_config: { "database_encryption_key" => "explicit" } do
        it "passes even with a shipped default SECRET_KEY_BASE" do
          allow(Rails.application).to receive(:secret_key_base).and_return("OVERWRITE_ME")

          expect { described_class.validate_secret! }.not_to raise_error
        end
      end

      context "with the check disabled", with_env: { "OPENPROJECT_DISABLE__SECRET_KEY_BASE__CHECK" => "true" } do
        it "passes" do
          allow(Rails.application).to receive(:secret_key_base).and_return("OVERWRITE_ME")

          expect { described_class.validate_secret! }.not_to raise_error
        end
      end
    end

    it "passes outside production" do
      allow(Rails.application).to receive(:secret_key_base).and_return("OVERWRITE_ME")

      expect { described_class.validate_secret! }.not_to raise_error
    end
  end

  describe "Rails configuration at boot" do
    let(:env) do
      {
        "RAILS_ENV" => "test",
        "SECRET_KEY_BASE" => "boot-secret-key-base",
        "OPENPROJECT_DATABASE__ENCRYPTION__KEY" => "boot-explicit",
        "OPENPROJECT_DATABASE__ENCRYPTION__PREVIOUS__KEY" => "boot-previous"
      }
    end
    let(:script) do
      <<~RUBY
        Repository.type_for_attribute(:password)
        config = ActiveRecord::Encryption.config
        puts JSON.generate(
          keys: config.primary_key,
          salt: config.key_derivation_salt,
          digest: ActiveRecord::Encryption.key_generator.hash_digest_class.name,
          previous_schemes: config.previous_schemes.size
        )
      RUBY
    end

    it "configures Active Record encryption in a fresh process" do
      output, status = Open3.capture2e(env, "bin/rails", "runner", script, chdir: Rails.root.to_s)
      expect(status).to be_success, output

      expect(JSON.parse(output.lines.last)).to eq(
        "keys" => %w[boot-previous boot-secret-key-base boot-explicit],
        "salt" => described_class::KEY_DERIVATION_SALT,
        "digest" => "OpenSSL::Digest::SHA256",
        "previous_schemes" => 0
      )
    end
  end
end
