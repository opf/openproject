class Page < ActiveRecord::Base
  belongs_to :author
  has_many   :authors,  :through => :versions, :order => 'name'
  belongs_to :revisor,  :class_name => 'Author'
  has_many   :revisors, :class_name => 'Author', :through => :versions, :order => 'name'
  acts_as_versioned :if => :feeling_good? do
    def self.included(base)
      base.cattr_accessor :feeling_good
      base.feeling_good = true
      base.belongs_to :author
      base.belongs_to :revisor, :class_name => 'Author'
    end
    
    def feeling_good?
      @@feeling_good == true
    end
  end
end

module LockedPageExtension
  def hello_world
    'hello_world'
  end
end

class LockedPage < ActiveRecord::Base
  acts_as_versioned \
    :inheritance_column => :version_type, 
    :foreign_key        => :page_id, 
    :table_name         => :locked_pages_revisions, 
    :class_name         => 'LockedPageRevision',
    :version_column     => :lock_version,
    :limit              => 2,
    :if_changed         => :title,
    :extend             => LockedPageExtension
end

class SpecialLockedPage < LockedPage
end

class Author < ActiveRecord::Base
  has_many :pages
end