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
# rubocop:disable Lint/RedundantCopDisableDirective, Rails/HelperInstanceVariable
# TODO: We should not use instance variables in our rails helpers. Since this is a bigger piece of work, for now
# we just disable the respective cop. Due to a bug, we must also disable the redundancy cop.
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

  def sort_by_options(column, order, default_order, allowed_params: nil, **html_options)
    order ||= order_string(column, inverted: true) || default_order
    sort_by = html_options.delete(:param)

    sort_param = @sort_criteria.add(column.to_s, order).to_param(sort_by)

    sort_options = { sort_key(sort_by) => sort_param }
    allowed_params ||= %w[filters per_page expand columns]

    # Don't lose other params.
    safe_query_params(allowed_params).merge(sort_options)
  end

  # Returns a link which sorts by the named column.
  #
  # - column is the name of an attribute in the sorted record collection.
  # - the optional caption explicitly specifies the displayed link text.
  # - 2 CSS classes reflect the state of the link: sort and asc or desc
  #
  def sort_link(column, caption, default_order, allowed_params: nil, **html_options)
    caption ||= column.to_s.humanize

    sort_options = sort_by_options(column, nil, default_order, allowed_params:, **html_options)
    html_options.delete(:param) # remove the `param` as we do not want it on our link-tag
    link_to_content_update(h(caption), sort_options, html_options.merge(rel: :nofollow))
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
    with_sort_header_options(column, allowed_params:, **options) do |col, cap, default_order, **opts|
      sort_link(col, cap, default_order, **opts)
    end
  end

  # Returns a clickable column header. When clicked, an action menu with multiple possible actions will
  # pop up. These actions include sorting, reordering the columns, filtering, etc.
  #
  # This is a more specific version of #sort_header_tag.
  # For "filter by" to work properly, you must pass a Hash for `filter_column_mapping`.
  def sort_header_with_action_menu(column, all_columns, filter_column_mapping = {}, allowed_params: nil, **options)
    with_sort_header_options(column, allowed_params:, **options) do |col, cap, default_order, **opts|
      action_menu(col, all_columns, cap, default_order, filter_column_mapping, **opts)
    end
  end

  # Extracts the given `options` and provides them to a block.
  # See #sort_header_tag and #sort_header_with_action_menu for usage examples.
  def with_sort_header_options(column, allowed_params: nil, **options)
    caption = get_caption(column, options)

    default_order = options.delete(:default_order) || "asc"
    lang = options.delete(:lang) || nil
    param = options.delete(:param) || :sort
    data = options.delete(:data) || {}

    options[:title] = sort_header_title(column, caption, options)
    options[:icon_only_header] = column == :favored

    within_sort_header_tag_hierarchy(options, sort_class(column)) do
      yield(column, caption, default_order, allowed_params:, param:, lang:, title: options[:title],
                                            sortable: options.fetch(:sortable, false), data:)
    end
  end

  def sort_key(key)
    key == :json ? :sortBy : :sort
  end

  def build_columns_link(columns, allowed_params: nil, **html_options)
    sort_by = html_options.delete(:param)
    sort_key = sort_key(sort_by)

    allowed_params ||= %w[filters per_page expand columns]
    projects_path(safe_query_params(allowed_params).merge(columns: columns.join(" "), sort_key => params[sort_key]))
  end

  # Tries to find the correct filter name for a column.
  #
  # Most columns play it safe and have their filter named just like them. This is the default.
  # Some filters have a different name than the column. For these cases, the correct filter name for the column
  # is read from the `filter_mapping`.
  # As a special case, some columns do not have any filter at all. For these, the `filter_mapping` defines `nil`
  # as filter name.
  #
  # @param column [Column] the column model that you would like to look up the filter name for
  # @param filter_mapping [Hash{String => String, nil} column name to filter name (to nil if no filter)
  # @return [String, nil] the correct filter name for the column. Returns nil if the column has no filter.
  def find_filter_for_column(column, filter_mapping)
    col = column.to_s

    filter_mapping.fetch(col, col)
  end

  # Renders an ActionMenu for a specific column. The ActionMenu offers options such as sorting, moving a column to
  # the left or right, filtering by the column (not available for all columns) or removing it.
  # Some of the method arguments are only needed for specific actions.
  def action_menu(column, table_columns, caption, default_order, filter_column_mapping = {},
                  allowed_params: nil, **html_options)
    caption ||= column.to_s.humanize

    filter = find_filter_for_column(column, filter_column_mapping)
    sortable = html_options.delete(:sortable)

    # `param` is not needed in the `content_arguments`, but should remain in the `html_options`.
    # It is important for keeping the current state in the GET parameters of each link used in
    # the action menu.
    content_args = html_options.merge(rel: :nofollow, param: nil)

    render Primer::Alpha::ActionMenu.new(menu_id: "menu-#{column}") do |menu|
      action_button(menu, caption, favorite: column == :favored)

      # Some columns are not sortable or do not offer a suitable filter. Omit those actions for them.
      sort_actions(menu, column, default_order, content_args:, allowed_params:, **html_options) if sortable
      filter_action(menu, column, filter, content_args:) if filter

      move_column_actions(menu, column, table_columns, content_args:, allowed_params:, **html_options)
      add_and_remove_column_actions(menu, column, table_columns, content_args:, allowed_params:, **html_options)
    end
  end

  def action_button(menu, caption, favorite: false)
    menu.with_show_button(scheme: :link, color: :default, text_transform: :uppercase,
                          underline: false, display: :inline_flex,
                          classes: "generic-table--action-menu-button") do |button|
      if favorite
        # This column only shows an icon, no text.
        render Primer::Beta::Octicon.new(icon: "star-fill", color: :subtle, "aria-label": I18n.t(:label_favorite))
      else
        button.with_trailing_action_icon(icon: :"triangle-down")

        h(caption).to_s
      end
    end
  end

  def sort_actions(menu, column, default_order, content_args:, allowed_params: nil, **html_options)
    desc_sort_link = projects_path(sort_by_options(column, "desc", default_order, allowed_params:, **html_options))
    asc_sort_link = projects_path(sort_by_options(column, "asc", default_order, allowed_params:, **html_options))

    menu.with_item(**menu_options(label: t(:label_sort_descending),
                                  content_args:,
                                  data: { "test-selector" => "#{column}-sort-desc" },
                                  href: desc_sort_link)) do |item|
      item.with_leading_visual_icon(icon: :"sort-desc")
    end
    menu.with_item(**menu_options(label: t(:label_sort_ascending),
                                  content_args:,
                                  data: { "test-selector" => "#{column}-sort-asc" },
                                  href: asc_sort_link)) do |item|
      item.with_leading_visual_icon(icon: :"sort-asc")
    end
    menu.with_divider
  end

  def filter_action(menu, column, filter, content_args:)
    menu.with_item(**menu_options(label: t(:label_filter_by),
                                  content_args:,
                                  data: {
                                    "test-selector" => "#{column}-filter-by",
                                    action: "table-action-menu#filterBy",
                                    filter_name: filter
                                  })) do |item|
      item.with_leading_visual_icon(icon: :filter)
    end
    menu.with_divider
  end

  def move_column_actions(menu, column, selected_columns, content_args:, allowed_params: nil, **html_options)
    column_pos = selected_columns.index(column)
    return unless column_pos

    # Add left shift action if possible (i.e. current column is not the leftmost one)
    if column_pos > 0
      add_shift_action(menu, column, selected_columns, content_args, allowed_params, html_options, direction: :left)
    end

    # Add right shift action if possible (i.e. current column is not the rightmost one)
    if column_pos < selected_columns.length - 1
      add_shift_action(menu, column, selected_columns, content_args, allowed_params, html_options, direction: :right)
    end
  end

  def add_shift_action(menu, column, selected_columns, content_args, allowed_params, html_options, direction:)
    icon = direction == :left ? :"op-columns-left" : :"op-columns-right"
    label_key = direction == :left ? :label_move_column_left : :label_move_column_right
    test_selector = direction == :left ? "#{column}-move-col-left" : "#{column}-move-col-right"

    shifted_columns = shift_element(selected_columns, column, direction == :right ? :right : :left)
    shift_link = build_columns_link(shifted_columns, allowed_params:, **html_options)

    menu.with_item(**menu_options(label: t(label_key),
                                  content_args:,
                                  data: { "test-selector" => test_selector },
                                  href: shift_link)) do |item|
      item.with_leading_visual_icon(icon:)
    end
  end

  def add_and_remove_column_actions(menu, column, selected_columns, content_args:, allowed_params: nil, **html_options)
    config_view_modal_link = configure_view_modal_project_queries_path(projects_query_params)

    all_columns_except_this = selected_columns.reject { _1 == column }
    rm_column_link = build_columns_link(all_columns_except_this, allowed_params:, **html_options)

    menu.with_item(**menu_options(label: t(:label_add_column),
                                  content_args:,
                                  data: {
                                    controller: "async-dialog",
                                    "test-selector" => "#{column}-add-column"
                                  },
                                  href: config_view_modal_link)) do |item|
      item.with_leading_visual_icon(icon: :columns)
    end
    menu.with_divider
    menu.with_item(**menu_options(label: t(:label_remove_column),
                                  content_args:,
                                  data: {
                                    "test-selector" => "#{column}-remove-column"
                                  },
                                  scheme: :danger,
                                  href: rm_column_link)) do |item|
      item.with_leading_visual_icon(icon: :trash)
    end
  end

  # Searches for `item` in the given `array` and shifts the item
  # one index to the left or right (depending on `direction`).
  # Returns a copy of `array` with the shifted item order.
  def shift_element(array, item, direction = :left)
    array = array.dup
    index = array.index(item)
    return array unless index

    step = direction == :left ? -1 : 1

    new_index = index + step
    return array if new_index.negative? || new_index >= array.size

    array[index], array[new_index] = array[new_index], array[index]

    array
  end

  def menu_options(label:, content_args:, **extra_args)
    # The `title` should always be identical to `label`.
    content_arguments = content_args.merge(title: label)

    # Since `data` might already be set, do not override it, but instead merge with the given extra arguments.
    if extra_args[:data]
      content_arguments[:data] = content_arguments.fetch(:data, {}).merge(extra_args.delete(:data))
    end

    { label:, content_arguments: }.merge(extra_args)
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
    # A column with all icon and no text requires other styles:
    icon_header = options.delete(:icon_only_header) { false }
    outer_classes = icon_header ? " generic-table--header_no-padding" : ""
    inner_classes = icon_header ? " generic-table--header_centered generic-table--header_no-min-width" : ""

    content_tag "th", options do
      content_tag "div", class: "generic-table--sort-header-outer#{outer_classes}" do
        content_tag "div", class: "generic-table--sort-header#{inner_classes}" do
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
# rubocop:enable Rails/HelperInstanceVariable, Lint/RedundantCopDisableDirective
