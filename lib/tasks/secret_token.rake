#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

desc 'Generates a secret token file.'

file 'config/secret_token.yml' do
  path = Rails.root.join('config/secret_token.yml').to_s
  secret = SecureRandom.hex(64)
  File.open(path, 'w') do |f|
    f.write <<"EOF"
secret_token: '#{secret}'
EOF
  end
end

desc 'Generates a secret token file.'
task :generate_secret_token => ['config/secret_token.yml']
