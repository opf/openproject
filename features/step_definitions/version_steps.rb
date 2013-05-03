Then(/^the editable attributes of the version should be the following:$/) do |table|
  table.rows_hash.each do |key, value|
    case key
    when "Column in backlog"
      page.should have_select(key, :selected => value)
    when "Start date"
      page.should have_field(key, :with => value)
    else
      raise "Not an implemented attribute"
    end
  end
end

