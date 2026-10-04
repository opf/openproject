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
require "open_project/auth_plugins"

RSpec.describe OpenProject::Plugins::AuthPlugin, with_ee: %i[sso_auth_providers] do # rubocop:disable RSpec/SpecFilePathFormat
  let(:dummy_engine_klass) do
    Class.new { extend OpenProject::Plugins::AuthPlugin }
  end
  let(:strategies) { {} }
  let(:providers_a) do
    lambda { [{ name: "a1" }, { name: "a2" }] }
  end
  let(:providers_b) do
    lambda { [{ name: "b1" }] }
  end
  let(:providers_c) do
    lambda { [{ name: "c1" }] }
  end

  let(:middlewares) { [] }

  before do
    app = Object.new
    omniauth_builder = Object.new

    without_partial_double_verification do
      allow(omniauth_builder).to receive(:provider) { |strategy|
        middlewares << strategy
      }

      allow(app).to receive_message_chain(:config, :middleware, :use) { |_mw, &block| # rubocop:disable RSpec/MessageChain
        omniauth_builder.instance_eval(&block)
      }
    end

    allow(described_class).to receive(:strategies).and_return(strategies)
    without_partial_double_verification do
      allow(dummy_engine_klass).to receive(:engine_name).and_return("foobar")
      allow(dummy_engine_klass).to receive(:initializer) { |_, &block| app.instance_eval(&block) }
      allow(dummy_engine_klass).to receive_message_chain(:config, :to_prepare) { |_, &block| # rubocop:disable RSpec/MessageChain
        block.call
      }
    end
  end

  describe "ProviderBuilder" do
    before do
      pa = providers_a.call
      pb = providers_b.call
      pc = providers_c.call

      Class.new(dummy_engine_klass) do
        register_auth_providers do
          strategy :strategy_a do
            pa
          end
          strategy :strategy_b do
            pb
          end
        end
      end

      Class.new(dummy_engine_klass) do
        register_auth_providers do
          strategy :strategy_a do
            pc
          end
        end
      end
    end

    it "registers all strategies" do
      expect(strategies.keys.to_a).to eq %i[strategy_a strategy_b]
    end

    it "marks all strategies for persisting in the database" do
      expect(PluginAuthProvider.pluck(:slug)).to eq([])
      PluginAuthProvider.create_all_registered
      expect(PluginAuthProvider.pluck(:slug)).to contain_exactly("a1", "a2", "b1", "c1")
    end

    it "registers each strategy (i.e. middleware) only once" do
      expect(middlewares.size).to eq 2
      expect(middlewares).to eq %i[strategy_a strategy_b]
    end

    it "associates the correct providers with their respective strategies" do
      described_class.providers_for(:strategy_a)
      expect(described_class.providers_for(:strategy_a)).to eq [providers_a.call, providers_c.call].flatten
      expect(described_class.providers_for(:strategy_b)).to eq providers_b.call
    end
  end
end
