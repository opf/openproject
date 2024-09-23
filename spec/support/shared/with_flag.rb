#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

module WithFlagMixin
  module_function

  def with_flags(flags)
    flags.each do |k, value|
      name = "#{/(?:feature_)?(\w+?)(?:_active)?\??$/.match(k)[1]}_active?"

      raise "#{k} is not a valid flag" unless OpenProject::FeatureDecisions.respond_to?(name)

      allow(OpenProject::FeatureDecisions).to receive(name).and_return value
    end
  end
end

RSpec.configure do |config|
  config.include WithFlagMixin

  config.before :example, :with_flag do |example|
    value = example.metadata[:with_flag]
    case value
    when Symbol
      with_flags(value => true)
    else
      with_flags(value)
    end
  end
end
