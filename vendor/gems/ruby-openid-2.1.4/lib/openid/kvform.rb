
module OpenID

  class KVFormError < Exception
  end

  module Util

    def Util.seq_to_kv(seq, strict=false)
      # Represent a sequence of pairs of strings as newline-terminated
      # key:value pairs. The pairs are generated in the order given.
      #
      # @param seq: The pairs
      #
      # returns a string representation of the sequence
      err = lambda { |msg|
        msg = "seq_to_kv warning: #{msg}: #{seq.inspect}"
        if strict
          raise KVFormError, msg
        else
          Util.log(msg)
        end
      }

      lines = []
      seq.each { |k, v|
        if !k.is_a?(String)
          err.call("Converting key to string: #{k.inspect}")
          k = k.to_s
        end

        if !k.index("\n").nil?
          raise KVFormError, "Invalid input for seq_to_kv: key contains newline: #{k.inspect}"
        end

        if !k.index(":").nil?
          raise KVFormError, "Invalid input for seq_to_kv: key contains colon: #{k.inspect}"
        end

        if k.strip() != k
          err.call("Key has whitespace at beginning or end: #{k.inspect}")
        end

        if !v.is_a?(String)
          err.call("Converting value to string: #{v.inspect}")
          v = v.to_s
        end

        if !v.index("\n").nil?
          raise KVFormError, "Invalid input for seq_to_kv: value contains newline: #{v.inspect}"
        end

        if v.strip() != v
          err.call("Value has whitespace at beginning or end: #{v.inspect}")
        end

        lines << k + ":" + v + "\n"
      }

      return lines.join("")
    end

    def Util.kv_to_seq(data, strict=false)
      # After one parse, seq_to_kv and kv_to_seq are inverses, with no
      # warnings:
      #
      # seq = kv_to_seq(s)
      # seq_to_kv(kv_to_seq(seq)) == seq
      err = lambda { |msg|
        msg = "kv_to_seq warning: #{msg}: #{data.inspect}"
        if strict
          raise KVFormError, msg
        else
          Util.log(msg)
        end
      }

      lines = data.split("\n")
      if data.length == 0
        return []
      end

      if data[-1].chr != "\n"
        err.call("Does not end in a newline")
        # We don't expect the last element of lines to be an empty
        # string because split() doesn't behave that way.
      end

      pairs = []
      line_num = 0
      lines.each { |line|
        line_num += 1

        # Ignore blank lines
        if line.strip() == ""
          next
        end

        pair = line.split(':', 2)
        if pair.length == 2
          k, v = pair
          k_s = k.strip()
          if k_s != k
            msg = "In line #{line_num}, ignoring leading or trailing whitespace in key #{k.inspect}"
            err.call(msg)
          end

          if k_s.length == 0
            err.call("In line #{line_num}, got empty key")
          end

          v_s = v.strip()
          if v_s != v
            msg = "In line #{line_num}, ignoring leading or trailing whitespace in value #{v.inspect}"
            err.call(msg)
          end

          pairs << [k_s, v_s]
        else
          err.call("Line #{line_num} does not contain a colon")
        end
      }

      return pairs
    end

    def Util.dict_to_kv(d)
      return seq_to_kv(d.entries.sort)
    end

    def Util.kv_to_dict(s)
      seq = kv_to_seq(s)
      return Hash[*seq.flatten]
    end
  end
end
