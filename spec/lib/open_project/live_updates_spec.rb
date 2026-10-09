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

RSpec.describe OpenProject::LiveUpdates do
  describe ".changed_event" do
    it "names the event after the model" do
      expect(described_class.changed_event(WorkPackage)).to eq("op-dispatched:work-package-changed")
    end

    it "accepts a record" do
      expect(described_class.changed_event(build_stubbed(:project))).to eq("op-dispatched:project-changed")
    end
  end

  describe ".broadcast_changed" do
    let(:project) { build_stubbed(:project) }

    before do
      allow(described_class).to receive(:enabled?).and_return(enabled)
    end

    context "when live updates are enabled" do
      let(:enabled) { true }

      it "dispatches the record's changed event to the pages subscribed to the record" do
        expect { described_class.broadcast_changed(project) }
          .to have_broadcasted_to(project.to_gid_param)
          .with(a_string_including(%(action="dispatchEvent"), %(event-name="op-dispatched:project-changed")))
      end

      it "includes the Turbo request id so the tab that made the change can ignore it" do
        expect { Turbo.with_request_id("request-1") { described_class.broadcast_changed(project) } }
          .to have_broadcasted_to(project.to_gid_param)
          .with(a_string_including(%(detail="{&quot;requestId&quot;:&quot;request-1&quot;}")))
      end

      it "sends no request id for changes made outside a Turbo request" do
        expect { described_class.broadcast_changed(project) }
          .to have_broadcasted_to(project.to_gid_param)
          .with(a_string_including(%(detail="{}")))
      end
    end

    context "when live updates are not enabled" do
      let(:enabled) { false }

      it "raises instead of silently dropping the signal" do
        expect { described_class.broadcast_changed(project) }
          .to raise_error(described_class::NotEnabledError)
      end
    end
  end
end
