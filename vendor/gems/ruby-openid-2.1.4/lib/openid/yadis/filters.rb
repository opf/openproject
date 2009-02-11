# This file contains functions and classes used for extracting
# endpoint information out of a Yadis XRD file using the REXML
# XML parser.

#
module OpenID
  module Yadis
    class BasicServiceEndpoint
      attr_reader :type_uris, :yadis_url, :uri, :service_element

      # Generic endpoint object that contains parsed service
      # information, as well as a reference to the service element
      # from which it was generated. If there is more than one
      # xrd:Type or xrd:URI in the xrd:Service, this object represents
      # just one of those pairs.
      #
      # This object can be used as a filter, because it implements
      # fromBasicServiceEndpoint.
      #
      # The simplest kind of filter you can write implements
      # fromBasicServiceEndpoint, which takes one of these objects.
      def initialize(yadis_url, type_uris, uri, service_element)
        @type_uris = type_uris
        @yadis_url = yadis_url
        @uri = uri
        @service_element = service_element
      end

      # Query this endpoint to see if it has any of the given type
      # URIs. This is useful for implementing other endpoint classes
      # that e.g. need to check for the presence of multiple
      # versions of a single protocol.
      def match_types(type_uris)
        return @type_uris & type_uris
      end

      # Trivial transform from a basic endpoint to itself. This
      # method exists to allow BasicServiceEndpoint to be used as a
      # filter.
      #
      # If you are subclassing this object, re-implement this function.
      def self.from_basic_service_endpoint(endpoint)
        return endpoint
      end

      # A hack to make both this class and its instances respond to
      # this message since Ruby doesn't support static methods.
      def from_basic_service_endpoint(endpoint)
        return self.class.from_basic_service_endpoint(endpoint)
      end

    end

    # Take a list of basic filters and makes a filter that
    # transforms the basic filter into a top-level filter. This is
    # mostly useful for the implementation of make_filter, which
    # should only be needed for special cases or internal use by
    # this library.
    #
    # This object is useful for creating simple filters for services
    # that use one URI and are specified by one Type (we expect most
    # Types will fit this paradigm).
    #
    # Creates a BasicServiceEndpoint object and apply the filter
    # functions to it until one of them returns a value.
    class TransformFilterMaker
      attr_reader :filter_procs

      # Initialize the filter maker's state
      #
      # filter_functions are the endpoint transformer
      # Procs to apply to the basic endpoint. These are called in
      # turn until one of them does not return nil, and the result
      # of that transformer is returned.
      def initialize(filter_procs)
        @filter_procs = filter_procs
      end

      # Returns an array of endpoint objects produced by the
      # filter procs.
      def get_service_endpoints(yadis_url, service_element)
        endpoints = []

        # Do an expansion of the service element by xrd:Type and
        # xrd:URI
        Yadis::expand_service(service_element).each { |type_uris, uri, _|
          # Create a basic endpoint object to represent this
          # yadis_url, Service, Type, URI combination
          endpoint = BasicServiceEndpoint.new(
                yadis_url, type_uris, uri, service_element)

          e = apply_filters(endpoint)
          if !e.nil?
            endpoints << e
          end
        }
        return endpoints
      end

      def apply_filters(endpoint)
        # Apply filter procs to an endpoint until one of them returns
        # non-nil.
        @filter_procs.each { |filter_proc|
          e = filter_proc.call(endpoint)
          if !e.nil?
            # Once one of the filters has returned an endpoint, do not
            # apply any more.
            return e
          end
        }

        return nil
      end
    end

    class CompoundFilter
      attr_reader :subfilters

      # Create a new filter that applies a set of filters to an
      # endpoint and collects their results.
      def initialize(subfilters)
        @subfilters = subfilters
      end

      # Generate all endpoint objects for all of the subfilters of
      # this filter and return their concatenation.
      def get_service_endpoints(yadis_url, service_element)
        endpoints = []
        @subfilters.each { |subfilter|
          endpoints += subfilter.get_service_endpoints(yadis_url, service_element)
        }
        return endpoints
      end
    end

    # Exception raised when something is not able to be turned into a
    # filter
    @@filter_type_error = TypeError.new(
      'Expected a filter, an endpoint, a callable or a list of any of these.')

    # Convert a filter-convertable thing into a filter
    #
    # parts should be a filter, an endpoint, a callable, or a list of
    # any of these.
    def self.make_filter(parts)
      # Convert the parts into a list, and pass to mk_compound_filter
      if parts.nil?
        parts = [BasicServiceEndpoint]
      end

      if parts.is_a?(Array)
        return mk_compound_filter(parts)
      else
        return mk_compound_filter([parts])
      end
    end

    # Create a filter out of a list of filter-like things
    #
    # Used by make_filter
    #
    # parts should be a list of things that can be passed to make_filter
    def self.mk_compound_filter(parts)

      if !parts.respond_to?('each')
        raise TypeError, "#{parts.inspect} is not iterable"
      end

      # Separate into a list of callables and a list of filter objects
      transformers = []
      filters = []
      parts.each { |subfilter|
        if !subfilter.is_a?(Array)
          # If it's not an iterable
          if subfilter.respond_to?('get_service_endpoints')
            # It's a full filter
            filters << subfilter
          elsif subfilter.respond_to?('from_basic_service_endpoint')
            # It's an endpoint object, so put its endpoint conversion
            # attribute into the list of endpoint transformers
            transformers << subfilter.method('from_basic_service_endpoint')
          elsif subfilter.respond_to?('call')
            # It's a proc, so add it to the list of endpoint
            # transformers
            transformers << subfilter
          else
            raise @@filter_type_error
          end
        else
          filters << mk_compound_filter(subfilter)
        end
      }

      if transformers.length > 0
        filters << TransformFilterMaker.new(transformers)
      end

      if filters.length == 1
        return filters[0]
      else
        return CompoundFilter.new(filters)
      end
    end
  end
end
