class CopyRepositoriesLogEncoding < ActiveRecord::Migration
  def self.up
    encoding = Setting.commit_logs_encoding.to_s.strip
    encoding = encoding.blank? ? 'UTF-8' : encoding
    Repository.find(:all).each do |repo|
      scm = repo.scm_name
      case scm
        when 'Subversion', 'Mercurial', 'Git', 'Filesystem' 
          repo.update_attribute(:log_encoding, nil)
        else
          repo.update_attribute(:log_encoding, encoding)
      end
    end
  end

  def self.down
  end
end
