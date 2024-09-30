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
#       order_by: sort_clause,
#       per_page: 10
#   end
#
# View (table header in list.rhtml):
#
#   <thead>
#     <tr>
#       <%= sort_header_tag('id', title: 'Sort by contact ID') %>
#       <%= sort_header_tag('last_name', caption: 'Name') %>
#       <%= sort_header_tag('phone') %>
#       <%= sort_header_tag('address', width: 200) %>
#     </tr>
#   </thead>
#
# - Introduces instance variables: @sort_default, @sort_criteria
# - Introduces param :sort
#

module SortHelper
  class SortCriteria
    attr_reader :criteria

    def initialize
      @criteria = []
    end

    def available_criteria=(criteria)
      unless criteria.is_a?(Hash)
        criteria = criteria.inject({}) do |h, k|
          h[k] = k
          h
        end
      end
      @available_criteria = criteria
    end

    def from_param(param)
      @criteria = param.to_s.split(",").map { |s| s.split(":")[0..1] }
      normalize!
    end

    def criteria=(arg)
      @criteria = arg
      normalize!
    end

    def to_param(format = nil)
      if format == :json
        to_json_param
      else
        to_sort_param
      end
    end

    def to_sql
      sql = to_a.join(", ")
      sql.presence
    end

    def to_a
      @criteria
        .map { |c, o| [@available_criteria[c], o] }
        .reject { |c, _| c.nil? }
        .filter_map { |c, o| append_direction(Array(c), o) }
    end

    def to_query_hash
      criteria_with_direction
        .to_h
    end

    def map_each(&)
      to_a.map(&)
    end

    def add!(key, asc)
      @criteria.delete_if { |k, _o| k == key }
      @criteria = [[key, asc]] + @criteria
      normalize!
    end

    def add(*)
      r = self.class.new.from_param(to_param)
      r.add!(*)
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
      @criteria = @criteria.map do |s|
        s = s.to_a
        [s.first, !(s.last == false || s.last == "desc")]
      end

      if @available_criteria
        @criteria = @criteria.select { |k, _o| @available_criteria.has_key?(k) }
      end

      @criteria.slice!(3)
      self
    end

    def append_direction(criterion, asc = true)
      if asc
        criterion
      else
        criterion.map { |c| append_desc(c) }
      end
    end

    # Appends DESC to the sort criterion unless it has a fixed order
    def append_desc(criterion)
      if / (asc|desc)\z/i.match?(criterion)
        criterion
      else
        "#{criterion} DESC"
      end
    end

    def to_json_param
      JSON::dump(criteria_with_direction)
    end

    def criteria_with_direction
      @criteria.map { |k, o| [k, o ? :asc : :desc] }
    end

    def to_sort_param
      @criteria.map { |k, o| k + (o ? "" : ":desc") }.join(",")
    end
  end

  def sort_name
    controller_name + "_" + action_name + "_sort"
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
    criteria = case args.size
               when 1
                 args.first.is_a?(Array) ? args.first : [[args.first]]
               when 2
                 [[args.first, args.last]]
               else
                 raise ArgumentError
               end
    @sort_default = SortCriteria.new
    @sort_default.criteria = criteria
  end

  # Updates the sort state. Call this in the controller prior to calling
  # sort_clause.
  # - criteria can be either an array or a hash of allowed keys
  #
  def sort_update(criteria)
    @sort_criteria = SortCriteria.new
    @sort_criteria.available_criteria = criteria
    @sort_criteria.from_param(params[:sort] || session[sort_name])
    @sort_criteria.criteria = @sort_default.criteria if @sort_criteria.empty?
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

  def sort_columns
    @sort_criteria.criteria.map(&:first)
  end

  # Determines whether the current selected sort criteria
  # is identical to the default
  def default_sort_order?
    @sort_default.criteria == @sort_criteria.criteria
  end

  # Returns a link which sorts by the named column.
  #
  # - column is the name of an attribute in the sorted record collection.
  # - the optional caption explicitly specifies the displayed link text.
  # - 2 CSS classes reflect the state of the link: sort and asc or desc
  #
  def sort_link(column, caption, default_order, allowed_params: nil, **html_options)
    order = order_string(column, inverted: true) || default_order
    caption ||= column.to_s.humanize

    sort_by = html_options.delete(:param)

    sort_param = @sort_criteria.add(column.to_s, order).to_param(sort_by)
    sort_key = sort_by == :json ? :sortBy : :sort

    sort_options = { sort_key => sort_param }

    allowed_params ||= %w[filters per_page expand columns]

    # Don't lose other params.
    link_to_content_update(h(caption), safe_query_params(allowed_params).merge(sort_options), html_options.merge(rel: :nofollow))
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
  #   <%= sort_header_tag('id', title: 'Sort by contact ID') %>
  #
  #   Generates (for the users controller and if the table is sorted by the column)
  #     <th>
  #       <div class="generic-table--sort-header-outer">
  #         <div class="generic-table--sort-header">
  #           <span class="sort asc">
  #             <a href="/users?sort=id:desc%3Adesc">Id</a>
  #           </span>
  #         </div>
  #       </div>
  #     </th>
  #
  def sort_header_tag(column, allowed_params: nil, **options)
    caption = get_caption(column, options)

    default_order = options.delete(:default_order) || "asc"
    lang = options.delete(:lang) || nil
    param = options.delete(:param) || :sort
    data = options.delete(:data) || {}

    options[:title] = sort_header_title(column, caption, options)

    within_sort_header_tag_hierarchy(options, sort_class(column)) do
      sort_link(column, caption, default_order, allowed_params:, param:, lang:, title: options[:title], data:)
    end
  end

  def sort_header_with_action_menu(column, allowed_params: nil, **options)
    caption = get_caption(column, options)

    default_order = options.delete(:default_order) || "asc"
    lang = options.delete(:lang) || nil
    param = options.delete(:param) || :sort
    data = options.delete(:data) || {}

    options[:title] = sort_header_title(column, caption, options)

    within_sort_header_tag_hierarchy(options, sort_class(column)) do
      # FIXME: always render the action menu
      # if %w(name project_status public created_at).include?(column.to_s)
        action_menu(column, caption, default_order, allowed_params:, param:, lang:, title: options[:title], data:)
      # else
      #   sort_link(column, caption, default_order, allowed_params:, param:, lang:, title: options[:title], data:)
      # end
    end
  end

  def sort_key(key)
    key == :json ? :sortBy : :sort
  end

  def sort_by_options(column, order, default_order, allowed_params: nil, **html_options)
    order ||= order_string(column, inverted: true) || default_order

    sort_by = html_options.delete(:param)

    sort_param = @sort_criteria.add(column.to_s, order).to_param(sort_by)
    sort_key = sort_key(sort_by)

    sort_options = { sort_key => sort_param }
    allowed_params ||= %w[filters per_page expand columns]

    safe_query_params(allowed_params).merge(sort_options)
  end

  # FIXME: copied from ConfigureViewModalComponent
  def selected_columns_for_action_menu
    @selected_columns ||= @query
                            .selects
                            .map(&:attribute)
  end

  def build_columns_link(columns, allowed_params: nil, **html_options)
    sort_by = html_options.delete(:param)
    sort_key = sort_key(sort_by)

    allowed_params ||= %w[filters per_page expand columns]
    projects_path(safe_query_params(allowed_params).merge(columns: columns.join(" "), sort_key => params[sort_key]))
  end

  def shift_element(arr, str, direction=:left)
    arr = arr.dup
    index = arr.index(str)
    return arr unless index

    case direction
    when :left
      if index > 0
        arr[index], arr[index - 1] = arr[index - 1], arr[index]
      end
    when :right
      if index < arr.size - 1
        arr[index], arr[index + 1] = arr[index + 1], arr[index]
      end
    end

    arr
  end

  def filter_conversion(column)
    col = column.to_s

    # FIXME: description and project_status_description have NO action menu right now. Should be nil here, too.
    {
      "name" => "id",
      "project_status" => "project_status_code",
      "identifier" => nil,
      "required_disk_space" => nil,
    }.fetch(col, col)
  end

  def action_menu(column, caption, default_order, allowed_params: nil, **html_options)
    caption ||= column.to_s.humanize

    desc_sort_link = projects_path(sort_by_options(column, "desc", default_order, allowed_params:, **html_options))
    asc_sort_link = projects_path(sort_by_options(column, "asc", default_order, allowed_params:, **html_options))

    selected_columns = selected_columns_for_action_menu

    left_shift = shift_element(selected_columns, column)
    shift_left_link = build_columns_link(left_shift, allowed_params:, **html_options)

    right_shift = shift_element(selected_columns, column, :right)
    shift_right_link = build_columns_link(right_shift, allowed_params:, **html_options)

    all_columns_except_this = selected_columns.reject { _1 == column }
    rm_column_link = build_columns_link(all_columns_except_this, allowed_params:, **html_options)

    filter = filter_conversion(column)

    html_options.delete(:param)

    content_args = html_options.merge(rel: :nofollow)

    render Primer::Alpha::ActionMenu.new(menu_id: "menu-#{column.to_s}") do |menu|
      menu.with_show_button(scheme: :link, color: :default, text_transform: :uppercase,
                            underline: false, display: :inline_flex) do |button|
        button.with_trailing_action_icon(icon: :"triangle-down")
        "#{h(caption)}"
      end
      menu.with_item(label: t(:label_sort_descending),
                     content_arguments: content_args.merge(title: t(:label_sort_descending)),
                     href: desc_sort_link) do |item|
        item.with_leading_visual_icon(icon: "sort-desc")
      end
      # FIXME: the title must be unique per link! Else the href will be duplicated.
      # TODO: move the title creation to another method.
      menu.with_item(label: t(:label_sort_ascending),
                     content_arguments: content_args.merge(title: t(:label_sort_ascending)),
                     href: asc_sort_link) do |item|
        item.with_leading_visual_icon(icon: "sort-asc")
      end

      # Some columns do not offer a filter. Only show the option when filtering is possible.
      if filter
        menu.with_divider
        menu.with_item(label: t(:label_filter_by),
                       content_arguments: content_args.merge(
                         data: {
                           action: "table-action-menu#filterBy",
                           filter_name: filter
                         },
                         title: t(:label_filter_by)
                       )) do |item|
          item.with_leading_visual_icon(icon: "filter")
        end
      end

      menu.with_divider
      menu.with_item(label: t(:label_move_column_left),
                     content_arguments: content_args.merge(title: t(:label_move_column_left)),
                     href: shift_left_link) do |item|
        item.with_leading_visual_icon(icon: "op-columns-left")
      end
      menu.with_item(label: t(:label_move_column_right),
                     content_arguments: content_args.merge(title: t(:label_move_column_right)),
                     href: shift_right_link) do |item|
        item.with_leading_visual_icon(icon: "op-columns-right")
      end
      # TODO: title?
      menu.with_item(label: t(:label_add_column),
                     href: configure_view_modal_project_queries_path(projects_query_params),
                     content_arguments: content_args.merge(
                       data: { controller: "async-dialog" },
                       title: t(:label_add_column)
                     )) do |item|
        item.with_leading_visual_icon(icon: "columns")
      end
      menu.with_divider
      menu.with_item(label: t(:label_remove_column),
                     scheme: :danger,
                     content_arguments: content_args.merge(title: t(:label_remove_column)),
                     href: rm_column_link) do |item|
        item.with_leading_visual_icon(icon: "trash")
      end
    end
  end

  def sort_class(column)
    order = order_string(column)

    order.nil? ? nil : "sort #{order}"
  end

  def order_string(column, inverted: false)
    if column.to_s == @sort_criteria.first_key
      if @sort_criteria.first_asc?
        inverted ? "desc" : "asc"
      else
        inverted ? "asc" : "desc"
      end
    end
  end

  def within_sort_header_tag_hierarchy(options, classes, &)
    content_tag "th", options do
      content_tag "div", class: "generic-table--sort-header-outer" do
        content_tag "div", class: "generic-table--sort-header" do
          content_tag("span", class: classes, &)
        end
      end
    end
  end

  def sort_header_title(column, caption, options)
    if column.to_s == @sort_criteria.first_key
      order = @sort_criteria.first_asc? ? t(:label_ascending) : t(:label_descending)
      order + " #{t(:label_sorted_by, value: "\"#{caption}\"")}"
    else
      t(:label_sort_by, value: "\"#{caption}\"") unless options[:title]
    end
  end

  def get_caption(column, options)
    caption = options.delete(:caption)

    if caption.blank?
      caption = defined?(model) ? model.human_attribute_name(column.to_s) : column.humanize
    end

    caption
  end
end
