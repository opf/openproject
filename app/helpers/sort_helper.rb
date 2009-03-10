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
#     sort_update %w(first_name, last_name)
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
#     sort_update %w(first_name, last_name)
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
        criteria = criteria.inject({}) {|h,k| h[k] = k; h}
      end
      @available_criteria = criteria
    end
    
    def from_param(param)
      @criteria = param.to_s.split(',').collect {|s| s.split(':')[0..1]}
      normalize!
    end
    
    def to_param
      @criteria.collect {|k,o| k + (o ? '' : ':desc')}.join(',')
    end
    
    def to_sql
      sql = @criteria.collect do |k,o|
        if s = @available_criteria[k]
          (o ? s.to_a : s.to_a.collect {|c| "#{c} DESC"}).join(', ')
        end
      end.compact.join(', ')
      sql.blank? ? nil : sql
    end
    
    def add!(key, asc)
      @criteria.delete_if {|k,o| k == key}
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
    
    private
    
    def normalize!
      @criteria = @criteria.collect {|s| [s.first, (s.last == false || s.last == 'desc') ? false : true]}
      @criteria = @criteria.select {|k,o| @available_criteria.has_key?(k)} if @available_criteria
      @criteria.slice!(3)
      self
    end
  end

  # Initializes the default sort column (default_key) and sort order
  # (default_order).
  #
  # - default_key is a column attribute name.
  # - default_order is 'asc' or 'desc'.
  #
  def sort_init(default_key, default_order='asc')
    @sort_default = "#{default_key}:#{default_order}"
  end

  # Updates the sort state. Call this in the controller prior to calling
  # sort_clause.
  # - criteria can be either an array or a hash of allowed keys
  #
  def sort_update(criteria)
    sort_name = controller_name + '_' + action_name + '_sort'
    
    @sort_criteria = SortCriteria.new
    @sort_criteria.available_criteria = criteria
    @sort_criteria.from_param(params[:sort] || session[sort_name] || @sort_default)
    session[sort_name] = @sort_criteria.to_param
  end

  # Returns an SQL sort clause corresponding to the current sort state.
  # Use this to sort the controller's table items collection.
  #
  def sort_clause()
    @sort_criteria.to_sql
  end

  # Returns a link which sorts by the named column.
  #
  # - column is the name of an attribute in the sorted record collection.
  # - the optional caption explicitly specifies the displayed link text.
  # - 2 CSS classes reflect the state of the link: sort and asc or desc
  #
  def sort_link(column, caption, default_order)
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
    
    sort_options = { :sort => @sort_criteria.add(column.to_s, order).to_param }
    # don't reuse params if filters are present
    url_options = params.has_key?(:set_filter) ? sort_options : params.merge(sort_options)
    
     # Add project_id to url_options
    url_options = url_options.merge(:project_id => params[:project_id]) if params.has_key?(:project_id)

    link_to_remote(caption,
                  {:update => "content", :url => url_options, :method => :get},
                  {:href => url_for(url_options),
                   :class => css})
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
  # Renders:
  #
  #   <th title="Sort by contact ID" width="40">
  #     <a href="/contact/list?sort_order=desc&amp;sort_key=id">Id</a>
  #     &nbsp;&nbsp;<img alt="Sort_asc" src="/images/sort_asc.png" />
  #   </th>
  #
  def sort_header_tag(column, options = {})
    caption = options.delete(:caption) || column.to_s.humanize
    default_order = options.delete(:default_order) || 'asc'
    options[:title] = l(:label_sort_by, "\"#{caption}\"") unless options[:title]
    content_tag('th', sort_link(column, caption, default_order), options)
  end
end

