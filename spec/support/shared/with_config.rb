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

RSpec.configure do |config|
  config.before(:each) do |example|
    config = example.metadata[:with_config]
    if config.present?
      config = aggregate_mocked_configuration(example, config).with_indifferent_access

      allow(OpenProject::Configuration).to receive(:[]).and_call_original
      config.each do |k, v|
        allow(OpenProject::Configuration)
          .to receive(:[])
          .with(k.to_s)
          .and_return(v)

        allow(OpenProject::Configuration)
          .to receive(:[])
          .with(k.to_sym)
          .and_return(v)
      end
    end
  end
end
