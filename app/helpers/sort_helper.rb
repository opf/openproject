#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# Helpers to sort tables using clickable column headers.
#
# Author:  Stuart Rackham <srackham@methods.co.nz>, March 2005.
#          Jean-Philippe Lang, 2009
# License: This source code is released under the MIT license.
#
# - Consecutive clicks toggle the column's sort order.
# - Sort state is maintained by a session hash entry.
# - CSS classes identify sort column and state.
# - Typically used in conjunction with the Pagination module.
#
# Example code snippets:
#
# Controller:
#
#   helper :sort
#   include SortHelper
#
#   def list
#     sort_init 'last_name'
#     sort_update %w(first_name last_name)
#     @items = Contact.find_all nil, sort_clause
#   end
#
# Controller (using Pagination module):
#
#   helper :sort
#   include SortHelper
#
#   def list
#     sort_init 'last_name'
#     sort_update %w(first_name last_name)
#     @contact_pages, @items = paginate :contacts,
#       :order_by => sort_clause,
#       :per_page => 10
#   end
#
# View (table header in list.rhtml):
#
#   <thead>
#     <tr>
#       <%= sort_header_tag('id', :title => 'Sort by contact ID') %>
#       <%= sort_header_tag('last_name', :caption => 'Name') %>
#       <%= sort_header_tag('phone') %>
#       <%= sort_header_tag('address', :width => 200) %>
#     </tr>
#   </thead>
#
# - Introduces instance variables: @sort_default, @sort_criteria
# - Introduces param :sort
#

module SortHelper
  class SortCriteria
    def initialize
      @criteria = []
    end

    def available_criteria=(criteria)
      unless criteria.is_a?(Hash)
        criteria = criteria.inject({}) { |h, k| h[k] = k; h }
      end
      @available_criteria = criteria
    end

    def from_param(param)
      @criteria = param.to_s.split(',').map { |s| s.split(':')[0..1] }
      normalize!
    end

    def criteria=(arg)
      @criteria = arg
      normalize!
    end

    def to_param
      @criteria.map { |k, o| k + (o ? '' : ':desc') }.join(',')
    end

    def to_sql
      sql = @criteria.map do |k, o|
        if s = @available_criteria[k]
          (o ? Array(s) : Array(s).map { |c| append_desc(c) }).join(', ')
        end
      end.compact.join(', ')
      sql.blank? ? nil : sql
    end

    def add!(key, asc)
      @criteria.delete_if { |k, _o| k == key }
      @criteria = [[key, asc]] + @criteria
      normalize!
    end

    def add(*args)
      r = self.class.new.from_param(to_param)
      r.add!(*args)
      r
    end

    def first_key
      @criteria.first && @criteria.first.first
    end

    def first_asc?
      @criteria.first && @criteria.first.last
    end

    def empty?
      @criteria.empty?
    end

    private

    def normalize!
      @criteria ||= []
      @criteria = @criteria.map { |s|
        s = s.to_a
        [s.first, !(s.last == false || s.last == 'desc')]
      }

      if @available_criteria
        @criteria = @criteria.select { |k, _o| @available_criteria.has_key?(k) }
      end

      @criteria.slice!(3)
      self
    end

    # Appends DESC to the sort criterion unless it has a fixed order
    def append_desc(criterion)
      if criterion =~ / (asc|desc)\z/i
        criterion
      else
        "#{criterion} DESC"
      end
    end
  end

  def sort_name
    controller_name + '_' + action_name + '_sort'
  end

  # Initializes the default sort.
  # Examples:
  #
  #   sort_init 'name'
  #   sort_init 'id', 'desc'
  #   sort_init ['name', ['id', 'desc']]
  #   sort_init [['name', 'desc'], ['id', 'desc']]
  #
  def sort_init(*args)
    case args.size
    when 1
      @sort_default = args.first.is_a?(Array) ? args.first : [[args.first]]
    when 2
      @sort_default = [[args.first, args.last]]
    else
      raise ArgumentError
    end
  end

  # Updates the sort state. Call this in the controller prior to calling
  # sort_clause.
  # - criteria can be either an array or a hash of allowed keys
  #
  def sort_update(criteria)
    @sort_criteria = SortCriteria.new
    @sort_criteria.available_criteria = criteria
    @sort_criteria.from_param(params[:sort] || session[sort_name])
    @sort_criteria.criteria = @sort_default if @sort_criteria.empty?
    session[sort_name] = @sort_criteria.to_param
  end

  # Clears the sort criteria session data
  #
  def sort_clear
    session[sort_name] = nil
  end

  # Returns an SQL sort clause corresponding to the current sort state.
  # Use this to sort the controller's table items collection.
  #
  def sort_clause
    @sort_criteria.to_sql
  end

  # Returns a link which sorts by the named column.
  #
  # - column is the name of an attribute in the sorted record collection.
  # - the optional caption explicitly specifies the displayed link text.
  # - 2 CSS classes reflect the state of the link: sort and asc or desc
  #
  def sort_link(column, caption, default_order, html_options = {})
    css, order = nil, default_order

    if column.to_s == @sort_criteria.first_key
      if @sort_criteria.first_asc?
        css = 'sort asc'
        order = 'desc'
      else
        css = 'sort desc'
        order = 'asc'
      end
    end
    caption = column.to_s.humanize unless caption

    sort_options = { sort: @sort_criteria.add(column.to_s, order).to_param }
    url_options = params.merge(sort_options)

    # Add project_id to url_options
    url_options = url_options.merge(project_id: params[:project_id]) if params.has_key?(:project_id)

    link_to_content_update(h(caption), url_options, html_options.merge(class: css))
  end

  # Returns a table header <th> tag with a sort link for the named column
  # attribute.
  #
  # Options:
  #   :caption     The displayed link name (defaults to titleized column name).
  #   :title       The tag's 'title' attribute (defaults to 'Sort by :caption').
  #
  # Other options hash entries generate additional table header tag attributes.
  #
  # Example:
  #
  #   <%= sort_header_tag('id', :title => 'Sort by contact ID', :width => 40) %>
  #
  def sort_header_tag(column, options = {})
    caption = options.delete(:caption) || column.to_s.humanize
    default_order = options.delete(:default_order) || 'asc'
    lang = options.delete(:lang) || nil

    if column.to_s == @sort_criteria.first_key
      options[:title] = @sort_criteria.first_asc? ? l(:label_ascending) : l(:label_descending)
      options[:title] += " #{l(:label_sorted_by, "\"#{caption}\"")}"
    else
      options[:title] = l(:label_sort_by, "\"#{caption}\"") unless options[:title]
    end

    content_tag('th', sort_link(column, caption, default_order, lang: lang), options)
  end
end
