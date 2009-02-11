require "openid/util"
require "openid/cryptutil"

module OpenID

  # Encapsulates a Diffie-Hellman key exchange.  This class is used
  # internally by both the consumer and server objects.
  #
  # Read more about Diffie-Hellman on wikipedia:
  # http://en.wikipedia.org/wiki/Diffie-Hellman

  class DiffieHellman

    # From the OpenID specification
    @@default_mod = 155172898181473697471232257763715539915724801966915404479707795314057629378541917580651227423698188993727816152646631438561595825688188889951272158842675419950341258706556549803580104870537681476726513255747040765857479291291572334510643245094715007229621094194349783925984760375594985848253359305585439638443
    @@default_gen = 2

    attr_reader :modulus, :generator, :public

    # A new DiffieHellman object, using the modulus and generator from
    # the OpenID specification
    def DiffieHellman.from_defaults
      DiffieHellman.new(@@default_mod, @@default_gen)
    end

    def initialize(modulus=nil, generator=nil, priv=nil)
      @modulus = modulus.nil? ? @@default_mod : modulus
      @generator = generator.nil? ? @@default_gen : generator
      set_private(priv.nil? ? OpenID::CryptUtil.rand(@modulus-2) + 1 : priv)
    end

    def get_shared_secret(composite)
      DiffieHellman.powermod(composite, @private, @modulus)
    end

    def xor_secret(algorithm, composite, secret)
      dh_shared = get_shared_secret(composite)
      packed_dh_shared = OpenID::CryptUtil.num_to_binary(dh_shared)
      hashed_dh_shared = algorithm.call(packed_dh_shared)
      return DiffieHellman.strxor(secret, hashed_dh_shared)
    end

    def using_default_values?
      @generator == @@default_gen && @modulus == @@default_mod
    end

    private
    def set_private(priv)
      @private = priv
      @public = DiffieHellman.powermod(@generator, @private, @modulus)
    end

    def DiffieHellman.strxor(s, t)
      if s.length != t.length
        raise ArgumentError, "strxor: lengths don't match. " +
          "Inputs were #{s.inspect} and #{t.inspect}"
      end

      if String.method_defined? :bytes
        s.bytes.zip(t.bytes).map{|sb,tb| sb^tb}.pack('C*')
      else
        indices = 0...(s.length)
        chrs = indices.collect {|i| (s[i]^t[i]).chr}
        chrs.join("")
      end
    end

    # This code is taken from this post:
    # <http://blade.nagaokaut.ac.jp/cgi-bin/scat.\rb/ruby/ruby-talk/19098>
    # by Eric Lee Green.
    def DiffieHellman.powermod(x, n, q)
      counter=0
      n_p=n
      y_p=1
      z_p=x
      while n_p != 0
        if n_p[0]==1
          y_p=(y_p*z_p) % q
        end
        n_p = n_p >> 1
        z_p = (z_p * z_p) % q
        counter += 1
      end
      return y_p
    end

  end

end
