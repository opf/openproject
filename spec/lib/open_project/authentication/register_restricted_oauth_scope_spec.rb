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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::Authentication, ".register_restricted_oauth_scope" do # rubocop:disable RSpec/SpecFilePathFormat
  let(:doorkeeper_scopes) { Doorkeeper::OAuth::Scopes.new }
  let(:oauth_scope) { "op:resource:documents:read" }
  let(:restricted_to) { OpenProject::Authentication::Scope::API_V3 }

  subject(:register) { described_class.register_restricted_oauth_scope(oauth_scope, restricted_to:) }

  before do
    allow(Doorkeeper.configuration).to receive(:scopes).and_return(doorkeeper_scopes)
    allow(described_class).to receive_messages(internal_oauth_scope_registry: Set.new,
                                               restricted_oauth_scope_registry: Hash.new { |hash, key| hash[key] = Set.new })
  end

  it "registers the scope with Doorkeeper as internal and restricted to the Warden scope" do
    register

    expect(doorkeeper_scopes.all).to eq([oauth_scope])
    expect(described_class.internal_oauth_scopes).to eq([oauth_scope])
    expect(described_class.restricted_oauth_scopes(restricted_to)).to eq([oauth_scope])
  end

  it "is idempotent" do
    2.times { described_class.register_restricted_oauth_scope(oauth_scope, restricted_to:) }

    expect(doorkeeper_scopes.all).to eq([oauth_scope])
    expect(described_class.internal_oauth_scopes).to eq([oauth_scope])
    expect(described_class.restricted_oauth_scopes(restricted_to)).to eq([oauth_scope])
  end

  shared_examples "rejects the scope" do
    it "raises an ArgumentError and registers nothing" do
      expect { register }.to raise_error(ArgumentError)

      expect(doorkeeper_scopes.all).to be_empty
      expect(described_class.internal_oauth_scopes).to be_empty
      expect(described_class.restricted_oauth_scopes(restricted_to)).to be_empty
    end
  end

  {
    "missing op prefix" => "resource:documents:edit",
    "wrong prefix" => "xx:resource:documents:edit",
    "unknown kind" => "op:feature:documents:edit",
    "unknown resource" => "op:resource:wikis:edit",
    "too few segments" => "op:resource:documents",
    "too many segments" => "op:resource:documents:edit:all",
    "empty action" => "op:resource:documents:",
    "uppercase action" => "op:resource:documents:Edit",
    "invalid action" => "op:resource:documents:edit-all"
  }.each do |description, invalid_scope|
    context "with #{description} (#{invalid_scope})" do
      let(:oauth_scope) { invalid_scope }

      it_behaves_like "rejects the scope"
    end
  end

  it "names the scope and the expected format in the error message" do
    expect { described_class.register_restricted_oauth_scope("op:resource:wikis:edit", restricted_to:) }
      .to raise_error(ArgumentError, /"op:resource:wikis:edit".*op:<kind>:<resource>:<action>.*"resource".*"documents"/)
  end

  context "with an unknown Warden scope" do
    let(:restricted_to) { :unknown }

    it_behaves_like "rejects the scope"

    it "names the unknown Warden scope in the error message" do
      expect { register }.to raise_error(ArgumentError, "unknown Warden scope: unknown")
    end
  end
end
