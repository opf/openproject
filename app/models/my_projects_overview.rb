class MyProjectsOverview < ActiveRecord::Base
  serialize :top, Array
  serialize :left, Array
  serialize :right, Array
  serialize :hidden, Array
end
