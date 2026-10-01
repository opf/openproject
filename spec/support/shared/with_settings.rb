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

def aggregate_mocked_settings(example, settings)
  # We have to manually check parent groups for with_settings:,
  # since they are being ignored otherwise
  example.example_group.module_parents.each do |parent|
    if parent.respond_to?(:metadata) && parent.metadata[:with_settings]
      settings.reverse_merge!(parent.metadata[:with_settings])
    end
  end

  settings
end

RSpec.shared_context "with settings reset" do
  # Snapshot per-Definition mutable state once, captured early enough that
  # legitimate boot-time mutations (e.g. the 2FA plugin's TokenStrategyManager
  # populating `active_strategies`) are part of the baseline. Definition
  # objects are mutated in place by `override_value`, so a shallow `@all.dup`
  # doesn't restore them — both copies point at the same mutated object.
  shared_let(:definitions_snapshot) do
    Settings::Definition.all.transform_values do |definition|
      {
        definition: definition,
        value: definition.instance_variable_get(:@value).deep_dup,
        writable: definition.instance_variable_get(:@writable)
      }
    end.freeze
  end

  def reset(setting, **definitions)
    setting = setting.to_sym
    definitions = Settings::Definition::DEFINITIONS[setting] if definitions.empty?
    Settings::Definition.all.delete(setting)
    Settings::Definition.add(setting, **definitions)
  end

  def stub_configuration_yml
    # disable test env detection because loading of the config file is partially disabled in test env
    allow(Rails.env).to receive(:test?).and_return(false)
    allow(File)
      .to receive(:file?)
            .with(Rails.root.join("config/configuration.yml"))
            .and_return(true)

    # It is added to avoid warning about other File.read calls.
    allow(File).to receive(:read).and_call_original
    allow(File)
      .to receive(:read)
            .with(Rails.root.join("config/configuration.yml"))
            .and_return(configuration_yml)
  end

  before do
    Settings::Definition.instance_variable_set(:@file_config, nil)
  end

  after do
    # Rewind in-place @value/@writable mutations on each original Definition.
    definitions_snapshot.each_value do |snap|
      snap[:definition].instance_variable_set(:@value, snap[:value].deep_dup)
      snap[:definition].instance_variable_set(:@writable, snap[:writable])
    end

    # Rebuild @all from the snapshot, dropping Definitions added during the
    # test (e.g. `described_class.add(:bogus)`).
    Settings::Definition.instance_variable_set(
      :@all,
      definitions_snapshot.transform_values { |snap| snap[:definition] }
    )

    # Clear block-style overrides registered via add_value_override and the
    # cached file config so the next test re-reads from disk.
    Settings::Definition.clear_value_overrides
    Settings::Definition.instance_variable_set(:@file_config, nil)
  end
end

module WithSettingsMixin
  module_function

  def with_settings(settings)
    allow(Setting).to receive(:[]).and_call_original

    settings.each do |k, v|
      name = k.to_s.sub(/\?\Z/, "") # remove trailing question mark if present to get setting name

      raise "#{k} is not a valid setting" unless Setting.respond_to?(name)

      expect(name).not_to start_with("localized_"), -> do
        base = name[10..]

        "Don't use `#{name}` in `with_settings`. Do this: `with_settings: { #{base}: { \"en\" => \"#{v}\" } }`"
      end
      v = v.deep_stringify_keys if v.is_a?(Hash)

      allow(Setting).to receive(:[]).with(name).and_return v
      allow(Setting).to receive(:[]).with(name.to_sym).and_return v
    end
  end
end

RSpec.configure do |config|
  config.include WithSettingsMixin

  # examples tagged with `:settings_reset` will automatically have the settings
  # reset before the example, and restored after.
  config.include_context "with settings reset", :settings_reset

  config.before do |example|
    settings = example.metadata[:with_settings]
    if settings.present?
      settings = aggregate_mocked_settings(example, settings)
      with_settings(settings)
    end
  end
end

RSpec.shared_context "with settings" do
  before do
    with_settings(settings)
  end
end
