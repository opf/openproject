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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Llm::Capabilities do
  describe ".states_from" do
    subject(:states) { described_class.states_from(info) }

    context "with an embedding entry" do
      let(:info) { instance_double(RubyLLM::Model::Info, type: "embedding", capabilities: []) }

      it "reports embeddings only" do
        expect(states).to eq(embeddings: :supported)
      end
    end

    context "with a chat entry listing its capabilities" do
      let(:info) { instance_double(RubyLLM::Model::Info, type: "chat", capabilities: %w[function_calling vision]) }

      it "reports the listed ones as supported and the rest as unsupported" do
        expect(states).to eq(embeddings: :unsupported,
                             function_calling: :supported,
                             structured_output: :unsupported,
                             vision: :supported,
                             reasoning: :unsupported)
      end
    end

    context "with a chat entry listing no capability at all" do
      let(:info) { instance_double(RubyLLM::Model::Info, type: "chat", capabilities: []) }

      it "leaves the chat capabilities unknown rather than denying them" do
        expect(states).to eq(embeddings: :unsupported,
                             function_calling: :unknown,
                             structured_output: :unknown,
                             vision: :unknown,
                             reasoning: :unknown)
      end
    end
  end
end
