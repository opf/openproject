#-- encoding: UTF-8

module LoginSteps
  def login(login, password)
    # visit '/logout' # uncomment me if needed
    visit '/login'
    fill_in User.human_attribute_name(:login)+":", :with => login
    fill_in 'Password:', :with => password
    click_button 'Login »'
  end
end

World(LoginSteps)
