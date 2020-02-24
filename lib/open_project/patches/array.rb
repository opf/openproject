module OpenProject
  module Patches
    module Array
    end
  end
end

Array.send(:include, Redmine::Diff::Diffable)
