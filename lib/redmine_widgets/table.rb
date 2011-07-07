class Widget::Table < Widget::Base

  def resolve_table
    if @subject.group_bys.size == 1
      simple_table
    else
      fancy_table
    end
  end

  def simple_table
    Widget::Table::SimpleTable
  end
end