##
# Abstract cell. Subclass this for a concrete table.
class TableCell < RailsCell
  include UsersHelper
  include SortHelper
  include PaginationHelper
  include WillPaginate::ActionView

  options :groups, :roles, :status, :project

  class << self
    ##
    # Names used by sort logic meaning these names
    # will be used directly in the generated SQL queries.
    #
    # This will also generate getters for these columns
    # on the RowCell class for this TableCell. The getters
    # are calling the same methods on the model for the Row.
    # E.g.:
    #
    #   Users::TableCell.columns :weight
    #   model = Struct.new(:weight).new 42
    #   row_cell = Users::Table::RowCell.new model
    #   row_cell.weight == model.weight
    def columns(*names)
      return Array(@columns) if names.empty?

      @columns = names
      rc = row_class

      names.each do |name|
        rc.property name
      end
    end

    def add_column(name)
      @columns = Array(@columns) + [name]
      row_class.property name
    end

    def row_class
      mod = namespace || "Table"
      class_name = "RowCell"

      "#{mod}::#{class_name}".constantize
    rescue NameError
      raise(
        NameError,
        "#{mod}::#{class_name} required by #{mod}::TableCell not defined. " +
        "Expected to be defined in `app/cells/#{mod.underscore}/#{class_name.underscore}.rb`."
      )
    end

    def namespace
      name.split("::")[0..-2].join("::").presence
    end
  end

  def initialize(rows, opts = {}, &block)
    super

    sort_init *initial_sort.map(&:to_s)
    sort_update columns.map(&:to_s)
    @model = sort_and_paginate_collection model
  end

  def sort_and_paginate_collection(ar_collection)
    return ar_collection unless ar_collection.is_a? ActiveRecord::QueryMethods

    # sort_clause from SortHelper
    paginate_collection sort_collection(ar_collection, sort_clause, sort_columns.map(&:to_sym))
  end

  ##
  # Sorts the data to be displayed.
  #
  # @param query [ActiveRecord::QueryMethods] An active record collection.
  # @param sort_clause [String] The SQL used as the sort clause.
  # @param _sort_columns [Array[Symbol]] Columns that are used to sort.
  def sort_collection(query, sort_clause, _sort_columns)
    query.order sort_clause
  end

  def paginate_collection(query)
    query
      .page(page_param(controller.params))
      .per_page(per_page_param)
  end

  def show
    render
  end

  def rows
    model
  end

  def columns
    self.class.columns
  end

  def render_row(row)
    prefix = (self.class.namespace || "table").split("::").map(&:downcase).join("/")
    cell("#{prefix}/row", row, table: self).call
  end

  def initial_sort
    [columns.first, :asc]
  end

  ##
  # An array listing each column and its respective options.
  #
  # @return Array<Array>
  def headers
    columns.map { |name| [name.to_s, {}] }
  end

  # required by the sort helper

  def controller_name
    controller.controller_name
  end

  def action_name
    controller.action_name
  end
end
