##
# Abstract cell. Subclass this for a concrete row cell.
class RowCell < RailsCell
  include RemovedJsHelpersHelper

  def table
    options[:table]
  end

  def columns
    table.columns
  end

  def column_value(column)
    value = send column
    if value.html_safe?
      value
    else
      h(value)
    end
  end

  def row_css_id
    nil
  end

  def row_css_class
    ""
  end

  def column_css_class(column)
    column_css_classes[column]
  end

  def column_css_classes
    entries = columns.map { |name| [name, name] }

    Hash[entries]
  end

  def column_title(_column)
    nil
  end

  def button_links
    []
  end
end
