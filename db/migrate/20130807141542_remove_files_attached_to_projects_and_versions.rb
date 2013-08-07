class RemoveFilesAttachedToProjectsAndVersions < ActiveRecord::Migration
  def up
    if  Attachment.where(:container_type => ['Version','Project']).any?
      raise "There are still attachments attached to Versions or Projects, please remove them."
    end
    #undocument this code if you want do delete all existing files attached to projects and versions
    #path = Rails.root.to_s + '/files/'
    #Attachment.where(:container_type => ['Version','Project']).each do |attachment|
    #  file = path + attachment.disk_filename
    #  File.delete(file) if File.exists?(file)
    #end
    #Attachment.where(:container_type => ['Version','Project']).delete_all
  end

  def down
  end
end
