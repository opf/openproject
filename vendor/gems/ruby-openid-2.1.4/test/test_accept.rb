
require 'test/unit'
require 'openid/yadis/accept'
require 'openid/extras'
require 'openid/util'

module OpenID

  class AcceptTest < Test::Unit::TestCase
    include TestDataMixin

    def getTestData()
      # Read the test data off of disk
      #
      # () -> [(int, str)]
      lines = read_data_file('accept.txt')
      line_no = 1
      return lines.collect { |line|
        pair = [line_no, line]
        line_no += 1
        pair
      }
    end

    def chunk(lines)
      # Return groups of lines separated by whitespace or comments
      #
      # [(int, str)] -> [[(int, str)]]
      chunks = []
      chunk = []
      lines.each { |lineno, line|
        stripped = line.strip()
        if (stripped == '') or stripped.starts_with?('#')
          if chunk.length > 0
            chunks << chunk
            chunk = []
          end
        else
          chunk << [lineno, stripped]
        end
      }

      if chunk.length > 0
        chunks << chunk
      end

      return chunks
    end

    def parseLines(chunk)
      # Take the given chunk of lines and turn it into a test data
      # dictionary
      #
      # [(int, str)] -> {str:(int, str)}
      items = {}
      chunk.each { |lineno, line|
        header, data = line.split(':', 2)
        header = header.downcase
        items[header] = [lineno, data.strip]
      }
      return items
    end

    def parseAvailable(available_text)
      # Parse an Available: line's data
      #
      # str -> [str]
      return available_text.split(',', -1).collect { |s| s.strip }
    end

    def parseExpected(expected_text)
      # Parse an Expected: line's data
      #
      # str -> [(str, float)]
      expected = []
      if expected_text != ''
        expected_text.split(',', -1).each { |chunk|
          chunk = chunk.strip
          mtype, qstuff = chunk.split(';', -1)
          mtype = mtype.strip
          Util.assert(!mtype.index('/').nil?)
          qstuff = qstuff.strip
          q, qstr = qstuff.split('=', -1)
          Util.assert(q == 'q')
          qval = qstr.to_f
          expected << [mtype, qval]
        }
      end

      return expected
    end

    def test_accept_headers
      lines = getTestData()
      chunks = chunk(lines)
      data_sets = chunks.collect { |chunk| parseLines(chunk) }
      cases = []
      data_sets.each { |data|
        lnos = []
        lno, header = data['accept']
        lnos << lno
        lno, avail_data = data['available']
        lnos << lno
        begin
          available = parseAvailable(avail_data)
        rescue
          print 'On line', lno
          raise
        end

        lno, exp_data = data['expected']
        lnos << lno
        begin
          expected = parseExpected(exp_data)
        rescue
          print 'On line', lno
          raise
        end

        descr = sprintf('MatchAcceptTest for lines %s', lnos)

        # Test:
        accepted = Yadis.parse_accept_header(header)
        actual = Yadis.match_types(accepted, available)
        assert_equal(expected, actual)

        assert_equal(Yadis.get_acceptable(header, available),
                     expected.collect { |mtype, _| mtype })
      }
    end

    def test_generate_accept_header
      # TODO: move this into a test case file and write parsing code
      # for it.

      # Form: [input_array, expected_header_string]
      cases = [
               # Empty input list
               [[], ""],
               # Content type name only; no q value
               [["test"], "test"],
               # q = 1.0 should be omitted from the header
               [[["test", 1.0]], "test"],
               # Test conversion of float to string
               [["test", ["with_q", 0.8]], "with_q; q=0.8, test"],
               # Allow string q values, too
               [["test", ["with_q_str", "0.7"]], "with_q_str; q=0.7, test"],
               # Test q values out of bounds
               [[["test", -1.0]], nil],
               [[["test", 1.1]], nil],
               # Test sorting of types by q value
               [[["middle", 0.5], ["min", 0.1], "max"],
                "min; q=0.1, middle; q=0.5, max"],

              ].each { |input, expected_header|

        if expected_header.nil?
          assert_raise(ArgumentError) {
            Yadis.generate_accept_header(*input)
          }
        else
          assert_equal(expected_header, Yadis.generate_accept_header(*input),
                       [input, expected_header].inspect)
        end
      }
    end

  end

end
