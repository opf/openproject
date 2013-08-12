class RemoveFilesAttachedToProjectsAndVersions < ActiveRecord::Migration
  def up
    if  Attachment.where(:container_type => ['Version','Project']).any?
      raise "There are still attachments attached to Versions or Projects, please remove them."
    end
    #uncomment this code if you want do delete all existing files attached to projects and versions
    #Attachment.where(:container_type => ['Version','Project']).destroy_all
  end

  def down
  end
end
