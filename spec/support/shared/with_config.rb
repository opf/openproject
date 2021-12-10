#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

class WithConfig
  attr_reader :context

  def initialize(context)
    @context = context
  end

  ##
  # We need this so calls to rspec mocks (allow, expect etc.) will work here as expected.
  def method_missing(method, *args, &block)
    if context.respond_to?(method)
      context.send method, *args, &block
    else
      super
    end
  end

  ##
  # Stubs the given configurations.
  #
  # @config [Hash] Hash containing the configurations with keys as seen in `configuration.rb`.
  def before(example, config)
    allow(OpenProject::Configuration).to receive(:[]).and_call_original

    aggregate_mocked_configuration(example, config)
      .with_indifferent_access
      .each { |k, v| stub_key(k, v) }
  end

  def stub_key(key, value)
    allow(OpenProject::Configuration)
      .to receive(:[])
      .with(key.to_s)
      .and_return(value)

    allow(OpenProject::Configuration)
      .to receive(:[])
      .with(key.to_sym)
      .and_return(value)
  end

  def aggregate_mocked_configuration(example, config)
    # We have to manually check parent groups for with_config:,
    # since they are being ignored otherwise
    example.example_group.module_parents.each do |parent|
      if parent.respond_to?(:metadata) && parent.metadata[:with_config]
        config.reverse_merge!(parent.metadata[:with_config])
      end
    end

    config
  end
end

RSpec.configure do |config|
  config.before(:each) do |example|
    with_config = example.metadata[:with_config]

    WithConfig.new(self).before example, with_config if with_config.present?
  end
end
