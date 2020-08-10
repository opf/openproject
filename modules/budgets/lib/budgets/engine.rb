module Budgets
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine
  end
end
