
require 'test/unit'
require 'openid/yadis/filters'

module OpenID
  class BasicServiceEndpointTest < Test::Unit::TestCase
    def test_match_types
      # Make sure the match_types operation returns the expected
      # results with various inputs.
      types = ["urn:bogus", "urn:testing"]
      yadis_url = "http://yadis/"

      no_types_endpoint = Yadis::BasicServiceEndpoint.new(yadis_url, [], nil, nil)

      some_types_endpoint = Yadis::BasicServiceEndpoint.new(yadis_url, types,
                                                            nil, nil)

      assert(no_types_endpoint.match_types([]) == [])
      assert(no_types_endpoint.match_types(["urn:absent"]) == [])

      assert(some_types_endpoint.match_types([]) == [])
      assert(some_types_endpoint.match_types(["urn:absent"]) == [])
      assert(some_types_endpoint.match_types(types) == types)
      assert(some_types_endpoint.match_types([types[1], types[0]]) == types)
      assert(some_types_endpoint.match_types([types[0]]) == [types[0]])
      assert(some_types_endpoint.match_types(types + ["urn:absent"]) == types)
    end

    def test_from_basic_service_endpoint
      # Check BasicServiceEndpoint.from_basic_service_endpoint
      endpoint = "unused"
      e = Yadis::BasicServiceEndpoint.new(nil, [], nil, nil)

      assert(Yadis::BasicServiceEndpoint.from_basic_service_endpoint(endpoint) ==
             endpoint)
      assert(e.from_basic_service_endpoint(endpoint) ==
             endpoint)
    end
  end

  class TransformFilterMakerTest < Test::Unit::TestCase
    def make_service_element(types, uris)
      service = REXML::Element.new('Service')
      types.each { |type_text|
        service.add_element('Type').text = type_text
      }
      uris.each { |uri_text|
        service.add_element('URI').text = uri_text
      }
      return service
    end
    def test_get_service_endpoints
      yadis_url = "http://yad.is/"
      uri = "http://uri/"
      type_uris = ["urn:type1", "urn:type2"]
      element = make_service_element(type_uris, [uri])

      data = [
              [type_uris, uri, element],
             ]

      filters = [Proc.new { |endpoint|
                   if endpoint.service_element == element
                     endpoint
                   else
                     nil
                   end
                 }
                ]

      tf = Yadis::TransformFilterMaker.new(filters)
      result = tf.get_service_endpoints(yadis_url, element)

      assert_equal(result[0].yadis_url, yadis_url, result)
      assert_equal(result[0].uri, uri, result)
    end

    def test_empty_transform_filter
      # A transform filter with no filter procs should return nil.
      endpoint = "unused"
      t = Yadis::TransformFilterMaker.new([])
      assert(t.apply_filters(endpoint).nil?)
    end

    def test_nil_filter
      # A transform filter with a single nil filter should return nil.
      nil_filter = Proc.new { |endpoint| nil }
      t = Yadis::TransformFilterMaker.new([nil_filter])
      endpoint = "unused"
      assert(t.apply_filters(endpoint).nil?)
    end

    def test_identity_filter
      # A transform filter with an identity filter should return the
      # input.
      identity_filter = Proc.new { |endpoint| endpoint }
      t = Yadis::TransformFilterMaker.new([identity_filter])
      endpoint = "unused"
      assert(t.apply_filters(endpoint) == endpoint)
    end

    def test_return_different_endpoint
      # Make sure the result of the filter is returned, rather than
      # the input.
      returned_endpoint = "returned endpoint"
      filter = Proc.new { |endpoint| returned_endpoint }
      t = Yadis::TransformFilterMaker.new([filter])
      endpoint = "unused"
      assert(t.apply_filters(endpoint) == returned_endpoint)
    end

    def test_multiple_filters
      # Check filter fallback behavior on different inputs.
      odd, odd_result = 45, "odd"
      even, even_result = 46, "even"

      filter_odd = Proc.new { |endpoint|
        if endpoint % 2 == 1
          odd_result
        else
          nil
        end
      }

      filter_even = Proc.new { |endpoint|
        if endpoint % 2 == 0
          even_result
        else
          nil
        end
      }

      t = Yadis::TransformFilterMaker.new([filter_odd, filter_even])
      assert(t.apply_filters(odd) == odd_result)
      assert(t.apply_filters(even) == even_result)
    end
  end

  class BogusServiceEndpointExtractor
    def initialize(data)
      @data = data
    end

    def get_service_endpoints(yadis_url, service_element)
      return @data
    end
  end

  class CompoundFilterTest < Test::Unit::TestCase
    def test_get_service_endpoints
      first = ["bogus", "test"]
      second = ["third"]
      all = first + second

      subfilters = [
                    BogusServiceEndpointExtractor.new(first),
                    BogusServiceEndpointExtractor.new(second),
                   ]

      cf = Yadis::CompoundFilter.new(subfilters)
      assert(cf.get_service_endpoints("unused", "unused") == all)
    end
  end

  class MakeFilterTest < Test::Unit::TestCase
    def test_parts_nil
      result = Yadis.make_filter(nil)
      assert(result.is_a?(Yadis::TransformFilterMaker),
             result)
    end

    def test_parts_array
      e1 = Yadis::BasicServiceEndpoint.new(nil, [], nil, nil)
      e2 = Yadis::BasicServiceEndpoint.new(nil, [], nil, nil)

      result = Yadis.make_filter([e1, e2])
      assert(result.is_a?(Yadis::TransformFilterMaker),
             result)
      assert(result.filter_procs[0] == e1.method('from_basic_service_endpoint'))
      assert(result.filter_procs[1] == e2.method('from_basic_service_endpoint'))
    end

    def test_parts_single
      e = Yadis::BasicServiceEndpoint.new(nil, [], nil, nil)
      result = Yadis.make_filter(e)
      assert(result.is_a?(Yadis::TransformFilterMaker),
             result)
    end
  end

  class MakeCompoundFilterTest < Test::Unit::TestCase
    def test_no_filters
      result = Yadis.mk_compound_filter([])
      assert(result.subfilters == [])
    end

    def test_single_transform_filter
      f = Yadis::TransformFilterMaker.new([])
      assert(Yadis.mk_compound_filter([f]) == f)
    end

    def test_single_endpoint
      e = Yadis::BasicServiceEndpoint.new(nil, [], nil, nil)
      result = Yadis.mk_compound_filter([e])
      assert(result.is_a?(Yadis::TransformFilterMaker))

      # Expect the transform filter to call
      # from_basic_service_endpoint on the endpoint
      filter = result.filter_procs[0]
      assert(filter == e.method('from_basic_service_endpoint'),
             filter)
    end

    def test_single_proc
      # Create a proc that just returns nil for any endpoint
      p = Proc.new { |endpoint| nil }
      result = Yadis.mk_compound_filter([p])
      assert(result.is_a?(Yadis::TransformFilterMaker))

      # Expect the transform filter to call
      # from_basic_service_endpoint on the endpoint
      filter = result.filter_procs[0]
      assert(filter == p)
    end

    def test_multiple_filters_same_type
      f1 = Yadis::TransformFilterMaker.new([])
      f2 = Yadis::TransformFilterMaker.new([])

      # Expect mk_compound_filter to actually make a CompoundFilter
      # from f1 and f2.
      result = Yadis.mk_compound_filter([f1, f2])

      assert(result.is_a?(Yadis::CompoundFilter))
      assert(result.subfilters == [f1, f2])
    end

    def test_multiple_filters_different_type
      f1 = Yadis::TransformFilterMaker.new([])
      f2 = Yadis::BasicServiceEndpoint.new(nil, [], nil, nil)
      f3 = Proc.new { |endpoint| nil }

      e = Yadis::BasicServiceEndpoint.new(nil, [], nil, nil)
      f4 = [e]

      # Expect mk_compound_filter to actually make a CompoundFilter
      # from f1 and f2.
      result = Yadis.mk_compound_filter([f1, f2, f3, f4])

      assert(result.is_a?(Yadis::CompoundFilter))

      assert(result.subfilters[0] == f1)
      assert(result.subfilters[1].filter_procs[0] ==
             e.method('from_basic_service_endpoint'))
      assert(result.subfilters[2].filter_procs[0] ==
             f2.method('from_basic_service_endpoint'))
      assert(result.subfilters[2].filter_procs[1] == f3)
    end

    def test_filter_type_error
      # Pass various non-filter objects and make sure the filter
      # machinery explodes.
      [nil, ["bogus"], [1], [nil, "bogus"]].each { |thing|
        assert_raise(TypeError) {
          Yadis.mk_compound_filter(thing)
        }
      }
    end
  end
end
