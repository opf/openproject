Shindo.tests('AWS::IAM | account policy requests', ['aws']) do

  tests('success') do
    tests("#update_account_password_policy(minimum_password_length, max_password_age, password_reuse_prevention,require_symbols,require_numbers,require_uppercase_characters, require_lowercase_characters,allow_users_to_change_password, hard_expiry, expire_passwords)").formats(AWS::IAM::Formats::BASIC) do
      minimum_password_length, password_reuse_prevention, max_password_age = 5
      require_symbols, require_numbers, require_uppercase_characters, require_lowercase_characters, allow_users_to_change_password, hard_expiry, expire_passwords = false
   
      Fog::AWS[:iam].update_account_password_policy(minimum_password_length, max_password_age, password_reuse_prevention,require_symbols,require_numbers,require_uppercase_characters, require_lowercase_characters,allow_users_to_change_password, hard_expiry, expire_passwords).body
    end

    tests("#get_account_password_policy()") do
      Fog::AWS[:iam].get_account_password_policy().body['AccountPasswordPolicy']
    end

    tests("#delete_account_password_policy()").formats(AWS::IAM::Formats::BASIC) do
  
      Fog::AWS[:iam].delete_account_password_policy().body
    end    
  end
end
