require 'active_support/concern'
require 'typed_dag/configuration'
require 'typed_dag/sql'
require 'typed_dag/edge/instance_methods'
require 'typed_dag/edge/class_methods'
require 'typed_dag/edge/closure_maintenance'
require 'typed_dag/edge/validations'
require 'typed_dag/edge/associations'

module TypedDag::Edge
  extend ActiveSupport::Concern

  included do
    include InstanceMethods
    include ClassMethods
    include Associations
    include ClosureMaintenance
    include Validations
  end
end
