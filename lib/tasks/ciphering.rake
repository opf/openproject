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


namespace :db do
  desc 'Encrypts SCM and LDAP passwords in the database.'
  task :encrypt => :environment do
    unless (Repository.encrypt_all(:password) &&
      AuthSource.encrypt_all(:account_password))
      raise "Some objects could not be saved after encryption, update was rollback'ed."
    end
  end

  desc 'Decrypts SCM and LDAP passwords in the database.'
  task :decrypt => :environment do
    unless (Repository.decrypt_all(:password) &&
      AuthSource.decrypt_all(:account_password))
      raise "Some objects could not be saved after decryption, update was rollback'ed."
    end
  end
end
