#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'open_project/auth_plugins'

describe OpenProject::Plugins::AuthPlugin do

  class MockEngine
    extend OpenProject::Plugins::AuthPlugin
  end

  let(:strategies) { {} }
  let(:providers_a) do
    lambda { [{ name: 'a1' }, { name: 'a2' }] }
  end
  let(:providers_b) do
    lambda { [{ name: 'b1' }] }
  end
  let(:providers_c) do
    lambda { [{ name: 'c1' }] }
  end

  let(:middlewares) { [] }

  before do
    app = Object.new
    omniauth_builder = Object.new

    allow(omniauth_builder).to receive(:provider) { |strategy|
      middlewares << strategy
    }

    allow(app).to receive_message_chain(:config, :middleware, :use) { |_mw, &block|
      omniauth_builder.instance_eval(&block)
    }

    allow(OpenProject::Plugins::AuthPlugin).to receive(:strategies).and_return(strategies)
    allow(MockEngine).to receive(:engine_name).and_return('foobar')
    allow(MockEngine).to receive(:initializer) { |_, &block| app.instance_eval(&block) }
  end

  describe 'ProviderBuilder' do
    before do
      pa = providers_a.call
      pb = providers_b.call
      pc = providers_c.call

      Class.new(MockEngine) do
        register_auth_providers do
          strategy :strategy_a do; pa; end
          strategy :strategy_b do; pb; end
        end
      end

      Class.new(MockEngine) do
        register_auth_providers do
          strategy :strategy_a do; pc; end
        end
      end
    end

    it 'should register all strategies' do
      expect(strategies.keys.to_a).to eq [:strategy_a, :strategy_b]
    end

    it 'should register register each strategy (i.e. middleware) only once' do
      expect(middlewares.size).to eq 2
      expect(middlewares).to eq [:strategy_a, :strategy_b]
    end

    it 'should associate the correct providers with their respective strategies' do
      expect(OpenProject::Plugins::AuthPlugin.providers_for(:strategy_a)).to eq [providers_a.call, providers_c.call].flatten
      expect(OpenProject::Plugins::AuthPlugin.providers_for(:strategy_b)).to eq providers_b.call
    end
  end
end
