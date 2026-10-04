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

RSpec.describe OpenProject::Webhooks do
  describe ".register_hook" do
    after do
      described_class.unregister_hook("testhook1")
    end

    it "succeeds" do
      described_class.register_hook("testhook1") {}
    end
  end

  describe ".find" do
    let!(:hook) { described_class.register_hook("testhook3") {} }

    after do
      described_class.unregister_hook("testhook3")
    end

    it "succeeds" do
      expect(described_class.find("testhook3")).to equal(hook)
    end
  end

  describe ".unregister_hook" do
    let(:probe) { lambda {} }

    before do
      described_class.register_hook("testhook2", &probe)
    end

    it "results in the hook no longer being found" do
      described_class.unregister_hook("testhook2")
      expect(described_class.find("testhook2")).to be_nil
    end
  end
end
