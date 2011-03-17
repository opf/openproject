class BurndownDay < ActiveRecord::Base
    unloadable
    belongs_to :version

end
