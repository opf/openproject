# frozen_string_literal: true

require 'logger'
require 'rack'
require 'rack/builder'
require 'rack/accept'
require 'rack/auth/basic'
require 'rack/auth/digest/md5'
require 'set'
require 'active_support/version'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/conversions'
require 'active_support/dependencies/autoload'
require 'active_support/notifications'
require 'i18n'

I18n.load_path << File.expand_path('../grape/locale/en.yml', __FILE__)

module Grape
  extend ::ActiveSupport::Autoload

  eager_autoload do
    autoload :API
    autoload :Endpoint

    autoload :Namespace

    autoload :Path
    autoload :Cookies
    autoload :Validations
    autoload :ErrorFormatter
    autoload :Formatter
    autoload :Parser
    autoload :Request
    autoload :Env, 'grape/util/env'
    autoload :Json, 'grape/util/json'
    autoload :Xml, 'grape/util/xml'
  end

  module Http
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :Headers
    end
  end

  module Exceptions
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :Base
      autoload :Validation
      autoload :ValidationArrayErrors
      autoload :ValidationErrors
      autoload :MissingVendorOption
      autoload :MissingMimeType
      autoload :MissingOption
      autoload :InvalidFormatter
      autoload :InvalidVersionerOption
      autoload :UnknownValidator
      autoload :UnknownOptions
      autoload :UnknownParameter
      autoload :InvalidWithOptionForRepresent
      autoload :IncompatibleOptionValues
      autoload :MissingGroupTypeError,          'grape/exceptions/missing_group_type'
      autoload :UnsupportedGroupTypeError,      'grape/exceptions/unsupported_group_type'
      autoload :InvalidMessageBody
      autoload :InvalidAcceptHeader
      autoload :InvalidVersionHeader
      autoload :MethodNotAllowed
      autoload :InvalidResponse
    end
  end

  module Extensions
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :DeepMergeableHash
      autoload :DeepSymbolizeHash
      autoload :Hash
    end
    module ActiveSupport
      extend ::ActiveSupport::Autoload
      eager_autoload do
        autoload :HashWithIndifferentAccess
      end
    end

    module Hashie
      extend ::ActiveSupport::Autoload
      eager_autoload do
        autoload :Mash
      end
    end
  end

  module Middleware
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :Base
      autoload :Versioner
      autoload :Formatter
      autoload :Error
      autoload :Globals
      autoload :Stack
      autoload :Helpers
    end

    module Auth
      extend ::ActiveSupport::Autoload
      eager_autoload do
        autoload :Base
        autoload :DSL
        autoload :StrategyInfo
        autoload :Strategies
      end
    end

    module Versioner
      extend ::ActiveSupport::Autoload
      eager_autoload do
        autoload :Path
        autoload :Header
        autoload :Param
        autoload :AcceptVersionHeader
      end
    end
  end

  module Util
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :InheritableValues
      autoload :StackableValues
      autoload :ReverseStackableValues
      autoload :InheritableSetting
      autoload :StrictHashConfiguration
      autoload :Registrable
    end
  end

  module ErrorFormatter
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :Base
      autoload :Json
      autoload :Txt
      autoload :Xml
    end
  end

  module Formatter
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :Json
      autoload :SerializableHash
      autoload :Txt
      autoload :Xml
    end
  end

  module Parser
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :Json
      autoload :Xml
    end
  end

  module DSL
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :API
      autoload :Callbacks
      autoload :Settings
      autoload :Configuration
      autoload :InsideRoute
      autoload :Helpers
      autoload :Middleware
      autoload :Parameters
      autoload :RequestResponse
      autoload :Routing
      autoload :Validations
      autoload :Logger
      autoload :Desc
    end
  end

  class API
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :Helpers
    end
  end

  module Presenters
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :Presenter
    end
  end

  module ServeFile
    extend ::ActiveSupport::Autoload
    eager_autoload do
      autoload :FileResponse
      autoload :FileBody
      autoload :SendfileResponse
    end
  end
end

require 'grape/config'
require 'grape/content_types'

require 'grape/util/lazy_value'
require 'grape/util/lazy_block'
require 'grape/util/endpoint_configuration'

require 'grape/validations/validators/base'
require 'grape/validations/attributes_iterator'
require 'grape/validations/single_attribute_iterator'
require 'grape/validations/multiple_attributes_iterator'
require 'grape/validations/validators/allow_blank'
require 'grape/validations/validators/as'
require 'grape/validations/validators/at_least_one_of'
require 'grape/validations/validators/coerce'
require 'grape/validations/validators/default'
require 'grape/validations/validators/exactly_one_of'
require 'grape/validations/validators/mutual_exclusion'
require 'grape/validations/validators/presence'
require 'grape/validations/validators/regexp'
require 'grape/validations/validators/same_as'
require 'grape/validations/validators/values'
require 'grape/validations/validators/except_values'
require 'grape/validations/params_scope'
require 'grape/validations/validators/all_or_none'
require 'grape/validations/types'
require 'grape/validations/validator_factory'

require 'grape/version'
