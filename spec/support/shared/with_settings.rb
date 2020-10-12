#-- encoding: UTF-8

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

RSpec.configure do |config|
  config.before(:each) do |example|
    settings = example.metadata[:with_settings]
    if settings.present?
      settings = aggregate_mocked_settings(example, settings)

      allow(Setting).to receive(:[]).and_call_original

      settings.each do |k, v|
        name = k.to_s.sub(/\?\Z/, '') # remove trailing question mark if present to get setting name

        raise "#{k} is not a valid setting" unless Setting.respond_to?(name)

        expect(name).not_to start_with("localized_"), ->() do
          base = name[10..-1]

          "Don't use `#{name}` in `with_settings`. Do this: `with_settings: { #{base}: { \"en\" => \"#{v}\" } }`"
        end

        allow(Setting).to receive(:[]).with(name).and_return v
        allow(Setting).to receive(:[]).with(name.to_sym).and_return v
      end
    end
  end
end
