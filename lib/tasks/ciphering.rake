
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
