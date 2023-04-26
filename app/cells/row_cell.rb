##
# Abstract cell. Subclass this for a concrete row cell.
class RowCell < RailsCell
  include RemovedJsHelpersHelper

  def table
    options[:table]
  end

  delegate :columns, to: :table

  def column_value(column)
    value = send column

    escaped(value)
  end

  def escaped(value)
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

    entries.to_h
  end

  def button_links
    []
  end

  def checkmark(condition)
    if condition
      op_icon 'icon icon-checkmark'
    end
  end
end
