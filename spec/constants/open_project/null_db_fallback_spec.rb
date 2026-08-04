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

RSpec.describe OpenProject::NullDbFallback do
  describe ".reset" do
    # Never let a stubbed run leave the suite believing it is on NullDB.
    after { described_class.send(:unapplied!) }

    context "when the fallback was never applied" do
      before { described_class.send(:unapplied!) }

      it "leaves the current connection alone" do
        allow(ActiveRecord::Base).to receive(:establish_connection)

        described_class.reset

        expect(ActiveRecord::Base).not_to have_received(:establish_connection)
      end
    end

    context "when the fallback was applied" do
      before do
        described_class.send(:applied!)
        allow(ActiveRecord::Base).to receive(:establish_connection)
      end

      # Resolving by environment name rather than reading config/database.yml is
      # what keeps DATABASE_URL working, so assert on the argument.
      it "re-establishes the connection for the current environment" do
        described_class.reset

        expect(ActiveRecord::Base).to have_received(:establish_connection).with(Rails.env.to_sym)
      end

      it "only reconnects once" do
        described_class.reset
        described_class.reset

        expect(ActiveRecord::Base).to have_received(:establish_connection).once
      end

      it "stays eligible for a retry when reconnecting fails" do
        allow(ActiveRecord::Base).to receive(:establish_connection).and_raise(ActiveRecord::ConnectionNotEstablished)

        expect { described_class.reset }.to raise_error(ActiveRecord::ConnectionNotEstablished)
        expect(described_class.send(:applied?)).to be true
      end
    end
  end
end
