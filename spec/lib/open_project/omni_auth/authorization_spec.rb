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

RSpec.describe OpenProject::OmniAuth::Authorization do
  describe ".after_login!" do
    let(:auth_hash) { Struct.new(:uid).new "bar" }
    let(:user)  { create(:user, mail: "foo@bar.de") }
    let(:state) { Struct.new(:number, :user_email, :uid).new 0, nil, nil }
    let(:collector) { [] }
    let!(:existing_callbacks) { OpenProject::OmniAuth::Authorization.after_login_callbacks.dup }

    before do
      OpenProject::OmniAuth::Authorization.after_login_callbacks.clear

      OpenProject::OmniAuth::Authorization.after_login do |_, _|
        state.number = 42
      end

      OpenProject::OmniAuth::Authorization.after_login do |user, auth|
        state.user_email = user.mail
        state.uid = auth.uid
      end

      OpenProject::OmniAuth::Authorization.after_login do |_, _, context|
        collector << context
      end
    end

    after do
      # Reset existing callbacks to avoid sideeffects
      OpenProject::OmniAuth::Authorization.after_login_callbacks.clear
      callbacks = OpenProject::OmniAuth::Authorization.after_login_callbacks

      existing_callbacks.each do |callback_block|
        callbacks << callback_block
      end
    end

    it 'triggers every callback setting uid to "bar", number to 42 and user_email to foo@bar.de' do
      OpenProject::OmniAuth::Authorization.after_login! user, auth_hash

      expect(state.number).to eq 42
      expect(state.user_email).to eq "foo@bar.de"
      expect(state.uid).to eq "bar"
    end

    it "optionally passes in a context" do
      context = double(:some_context)
      OpenProject::OmniAuth::Authorization.after_login! user, auth_hash, context
      expect(collector).to include(context)
    end
  end
end
