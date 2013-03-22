Then(/^the user "(.*?)" should( not)? be available as a participant$/) do |login, negative|
  user = User.find_by_login(login)

  step(%{I should#{negative} see "#{user.name}" within "#meeting-form table.list"})
end

