Then /^there should be a user with the following:$/ do |table|
  expected = table.rows_hash

  user = User.find_by_login(expected["login"])

  user.should_not be_nil

  expected.each do |key, value|
    user.send(key).should == value
  end
end
