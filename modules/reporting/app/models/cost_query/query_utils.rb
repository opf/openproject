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

module CostQuery::QueryUtils
  include Redmine::I18n
  include Report::QueryUtils

  def map_field(key, value)
    case key.to_s
    when "user_id"                          then value ? user_name(value.to_i) : ''
    when "tweek", "tyear", "tmonth", /_id$/ then value.to_i
    when "week"                             then value.to_i.divmod(100)
    when /_(on|at)$/                        then value ? value.to_dateish : Time.at(0)
    when /^custom_field/                    then value.to_s
    when "singleton_value"                  then value.to_i
    else super
    end
  end

  def user_name(id)
    # we have no identity map... :(
    cache[:user_name][id] ||= User.find(id).name
  end

  ##
  # Graceful, internationalized quoted string.
  #
  # @see quote_string
  # @param [Object] str String to quote/translate
  # @return [Object] Quoted, translated version
  def quoted_label(ident)
    "'#{quote_string l(ident)}'"
  end

  propagate!
end
