require 'active_support/lazy_load_hooks'
require 'awesome_nested_set/awesome_nested_set'

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send :extend, CollectiveIdea::Acts::NestedSet
end

ActiveSupport.on_load(:action_view) do
  require 'awesome_nested_set/helper'
  ActionView::Base.send :include, CollectiveIdea::Acts::NestedSet::Helper
end
