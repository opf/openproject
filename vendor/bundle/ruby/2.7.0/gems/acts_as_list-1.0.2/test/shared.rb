# frozen_string_literal: true

# Common shared behaviour.
module Shared
  autoload :List,           'shared_list'
  autoload :ListSub,        'shared_list_sub'
  autoload :ZeroBased,      'shared_zero_based'
  autoload :ArrayScopeList, 'shared_array_scope_list'
  autoload :TopAddition,    'shared_top_addition'
  autoload :NoAddition,     'shared_no_addition'
  autoload :Quoting,        'shared_quoting'
end
