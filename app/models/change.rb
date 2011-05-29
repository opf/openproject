class Change < ActiveRecord::Base
  belongs_to :changeset
  
  validates_presence_of :changeset_id, :action, :path
  before_save :init_path
  
  def relative_path
    changeset.repository.relative_path(path)
  end
  
  def init_path
    self.path ||= ""
  end
end
