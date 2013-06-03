#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
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
