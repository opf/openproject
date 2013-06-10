if Rails.env == 'test'
  puts 'Reducing minimum password length to 4 characters for test environment'
  # Set default minimum length to 4, this doesn't require writing to the database.
  # Migrations might not have run here.
  Setting.available_settings['password_min_length']['default'] = 4
end
