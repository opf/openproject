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

RSpec.describe OpenProject::Logging, "Log extenders" do
  subject { described_class.extend_payload!(payload, input_context) }

  let(:payload) do
    { method: "GET", action: "something", controller: "SomeController" }
  end

  let(:input_context) do
    {}
  end

  context "with an extender returning keys" do
    let(:return_value) do
      { some_hash: 123 }
    end

    let(:extender) do
      ->(_context) do
        return_value
      end
    end

    before do
      described_class.add_payload_extender(&extender)
    end

    after do
      described_class.instance_variable_set(:@payload_extenders, nil)
    end

    it "calls that extender as well as the default one" do
      allow(extender).to receive(:call).and_call_original

      expect(subject.keys).to contain_exactly :method, :action, :controller, :some_hash, :user
      expect(subject[:some_hash]).to eq 123
    end
  end

  context "with an extender raising an error" do
    let(:return_value) do
      { some_hash: 123 }
    end

    let(:extender) do
      ->(_context) do
        raise "This is not good."
      end
    end

    before do
      described_class.add_payload_extender(&extender)
    end

    after do
      described_class.instance_variable_set(:@payload_extenders, nil)
    end

    it "does not break the returned payload" do
      allow(extender).to receive(:call).and_call_original

      expect(subject.keys).to contain_exactly :method, :action, :controller, :user
      expect(subject[:some_hash]).to be_nil
    end
  end
end
