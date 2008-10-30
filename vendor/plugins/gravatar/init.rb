require 'gravatar'
ActionView::Base.send :include, GravatarHelper::PublicMethods
