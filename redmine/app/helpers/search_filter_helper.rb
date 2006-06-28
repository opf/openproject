# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

module SearchFilterHelper

	def search_filter_criteria(field, options = {})
		session[:search_filter] ||= {}
		session[:search_filter][field] ||= options
	#	session[:search_filter][field][:values] = options[:values] unless options[:values].nil?
	#	session[:search_filter][field][:label] = options[:label] unless options[:label].nil?
	end

	def search_filter_update
		session[:search_filter].each_key {|field| session[:search_filter][field][:value] = params[field]  }
		#@search_filter[:value] = params[@search_filter[:field]]
	end
	
	def search_filter_clause
		clause = "1=1"
		session[:search_filter].each {|field, criteria| clause = clause + " AND " + field + "='" + session[:search_filter][field][:value] + "'" unless session[:search_filter][field][:value].nil? || session[:search_filter][field][:value].empty? }
		clause
		#@search_filter[:field] + "='" + @search_filter[:value] + "'" unless @search_filter[:value].nil? || @search_filter[:value].empty?
	end
	
	def search_filter_tag(field)
		option_values = []
		#values = eval @search_filter[:values_expr]
		option_values = eval session[:search_filter][field][:values]
		
		content_tag("select", 
				content_tag("option", "[All]", :value => "") +
				options_from_collection_for_select(option_values, 
										"id",
										session[:search_filter][field][:label]  || "name",
										session[:search_filter][field][:value].to_i
										),
				:name => field
				)
	end

end