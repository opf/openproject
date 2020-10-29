require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe 'BCrypt::Engine' do
  describe '.calibrate(upper_time_limit_in_ms)' do
    context 'a tiny upper time limit provided' do
      it 'returns a minimum cost supported by the algorithm' do
        expect(BCrypt::Engine.calibrate(0.001)).to eq(4)
      end
    end
  end
end

describe "The BCrypt engine" do
  specify "should calculate the optimal cost factor to fit in a specific time" do
    first = BCrypt::Engine.calibrate(100)
    second = BCrypt::Engine.calibrate(400)
    expect(second).to be > first
  end
end

describe "Generating BCrypt salts" do

  specify "should produce strings" do
    expect(BCrypt::Engine.generate_salt).to be_an_instance_of(String)
  end

  specify "should produce random data" do
    expect(BCrypt::Engine.generate_salt).to_not equal(BCrypt::Engine.generate_salt)
  end

  specify "should raise a InvalidCostError if the cost parameter isn't numeric" do
    expect { BCrypt::Engine.generate_salt('woo') }.to raise_error(BCrypt::Errors::InvalidCost)
  end

  specify "should raise a InvalidCostError if the cost parameter isn't greater than 0" do
    expect { BCrypt::Engine.generate_salt(-1) }.to raise_error(BCrypt::Errors::InvalidCost)
  end
end

describe "Autodetecting of salt cost" do

  specify "should work" do
    expect(BCrypt::Engine.autodetect_cost("$2a$08$hRx2IVeHNsTSYYtUWn61Ou")).to eq 8
    expect(BCrypt::Engine.autodetect_cost("$2a$05$XKd1bMnLgUnc87qvbAaCUu")).to eq 5
    expect(BCrypt::Engine.autodetect_cost("$2a$13$Lni.CZ6z5A7344POTFBBV.")).to eq 13
  end

end

describe "Generating BCrypt hashes" do

  class MyInvalidSecret
    undef to_s
  end

  before :each do
    @salt = BCrypt::Engine.generate_salt(4)
    @password = "woo"
  end

  specify "should produce a string" do
    expect(BCrypt::Engine.hash_secret(@password, @salt)).to be_an_instance_of(String)
  end

  specify "should raise an InvalidSalt error if the salt is invalid" do
    expect { BCrypt::Engine.hash_secret(@password, 'nino') }.to raise_error(BCrypt::Errors::InvalidSalt)
  end

  specify "should raise an InvalidSecret error if the secret is invalid" do
    expect { BCrypt::Engine.hash_secret(MyInvalidSecret.new, @salt) }.to raise_error(BCrypt::Errors::InvalidSecret)
    expect { BCrypt::Engine.hash_secret(nil, @salt) }.not_to raise_error
    expect { BCrypt::Engine.hash_secret(false, @salt) }.not_to raise_error
  end

  specify "should call #to_s on the secret and use the return value as the actual secret data" do
    expect(BCrypt::Engine.hash_secret(false, @salt)).to eq BCrypt::Engine.hash_secret("false", @salt)
  end

  specify "should be interoperable with other implementations" do
    test_vectors = [
      # test vectors from the OpenWall implementation <https://www.openwall.com/crypt/>, found in wrapper.c
      ["U*U", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW"],
      ["U*U*", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.VGOzA784oUp/Z0DY336zx7pLYAy0lwK"],
      ["U*U*U", "$2a$05$XXXXXXXXXXXXXXXXXXXXXO", "$2a$05$XXXXXXXXXXXXXXXXXXXXXOAcXxm9kjPGEMsLznoKqmqw7tc8WCx4a"],
      ["0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789chars after 72 are ignored", "$2a$05$abcdefghijklmnopqrstuu", "$2a$05$abcdefghijklmnopqrstuu5s2v8.iXieOjg/.AySBTTZIIVFJeBui"],
      ["\xa3", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"],
      ["\xff\xff\xa3", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"],
      ["\xff\xff\xa3", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"],
      ["\xff\xff\xa3", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.nqd1wy.pTMdcvrRWxyiGL2eMz.2a85."],
      ["\xff\xff\xa3", "$2b$05$/OK.fbVrR/bpIqNJ5ianF.", "$2b$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e"],
      ["\xa3", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"],
      ["\xa3", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"],
      ["\xa3", "$2b$05$/OK.fbVrR/bpIqNJ5ianF.", "$2b$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq"],
      ["1\xa3" "345", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"],
      ["\xff\xa3" "345", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"],
      ["\xff\xa3" "34" "\xff\xff\xff\xa3" "345", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"],
      ["\xff\xa3" "34" "\xff\xff\xff\xa3" "345", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi"],
      ["\xff\xa3" "34" "\xff\xff\xff\xa3" "345", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.ZC1JEJ8Z4gPfpe1JOr/oyPXTWl9EFd."],
      ["\xff\xa3" "345", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.nRht2l/HRhr6zmCp9vYUvvsqynflf9e"],
      ["\xff\xa3" "345", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.nRht2l/HRhr6zmCp9vYUvvsqynflf9e"],
      ["\xa3" "ab", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"],
      ["\xa3" "ab", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.", "$2x$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"],
      ["\xa3" "ab", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.", "$2y$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS"],
      ["\xd1\x91", "$2x$05$6bNw2HLQYeqHYyBfLMsv/O", "$2x$05$6bNw2HLQYeqHYyBfLMsv/OiwqTymGIGzFsA4hOTWebfehXHNprcAS"],
      ["\xd0\xc1\xd2\xcf\xcc\xd8", "$2x$05$6bNw2HLQYeqHYyBfLMsv/O", "$2x$05$6bNw2HLQYeqHYyBfLMsv/O9LIGgn8OMzuDoHfof8AQimSGfcSWxnS"],
      ["\xaa"*72+"chars after 72 are ignored as usual", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.swQOIzjOiJ9GHEPuhEkvqrUyvWhEMx6"],
      ["\xaa\x55"*36, "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.R9xrDjiycxMbQE2bp.vgqlYpW5wx2yy"],
      ["\x55\xaa\xff"*24, "$2a$05$/OK.fbVrR/bpIqNJ5ianF.", "$2a$05$/OK.fbVrR/bpIqNJ5ianF.9tQZzcJfm3uj2NvJ/n5xkhpqLrMpWCe"],
      ["", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.", "$2a$05$CCCCCCCCCCCCCCCCCCCCC.7uG0VCzI2bS7j6ymqJi9CdcdxiRTWNy"],

      # test vectors from the Java implementation, found in https://github.com/spring-projects/spring-security/blob/master/crypto/src/test/java/org/springframework/security/crypto/bcrypt/BCryptTests.java
      ["", "$2a$06$DCq7YPn5Rq63x1Lad4cll.", "$2a$06$DCq7YPn5Rq63x1Lad4cll.TV4S6ytwfsfvkgY8jIucDrjc8deX1s."],
      ["", "$2a$08$HqWuK6/Ng6sg9gQzbLrgb.", "$2a$08$HqWuK6/Ng6sg9gQzbLrgb.Tl.ZHfXLhvt/SgVyWhQqgqcZ7ZuUtye"],
      ["", "$2a$10$k1wbIrmNyFAPwPVPSVa/ze", "$2a$10$k1wbIrmNyFAPwPVPSVa/zecw2BCEnBwVS2GbrmgzxFUOqW9dk4TCW"],
      ["", "$2a$12$k42ZFHFWqBp3vWli.nIn8u", "$2a$12$k42ZFHFWqBp3vWli.nIn8uYyIkbvYRvodzbfbK18SSsY.CsIQPlxO"],
      ["", "$2b$06$8eVN9RiU8Yki430X.wBvN.", "$2b$06$8eVN9RiU8Yki430X.wBvN.LWaqh2962emLVSVXVZIXJvDYLsV0oFu"],
      ["", "$2b$06$NlgfNgpIc6GlHciCkMEW8u", "$2b$06$NlgfNgpIc6GlHciCkMEW8uKOBsyvAp7QwlHpysOlKdtyEw50WQua2"],
      ["", "$2y$06$mFDtkz6UN7B3GZ2qi2hhaO", "$2y$06$mFDtkz6UN7B3GZ2qi2hhaO3OFWzNEdcY84ELw6iHCPruuQfSAXBLK"],
      ["", "$2y$06$88kSqVttBx.e9iXTPCLa5u", "$2y$06$88kSqVttBx.e9iXTPCLa5uFPrVFjfLH4D.KcO6pBiAmvUkvdg0EYy"],
      ["a", "$2a$06$m0CrhHm10qJ3lXRY.5zDGO", "$2a$06$m0CrhHm10qJ3lXRY.5zDGO3rS2KdeeWLuGmsfGlMfOxih58VYVfxe"],
      ["a", "$2a$08$cfcvVd2aQ8CMvoMpP2EBfe", "$2a$08$cfcvVd2aQ8CMvoMpP2EBfeodLEkkFJ9umNEfPD18.hUF62qqlC/V."],
      ["a", "$2a$10$k87L/MF28Q673VKh8/cPi.", "$2a$10$k87L/MF28Q673VKh8/cPi.SUl7MU/rWuSiIDDFayrKk/1tBsSQu4u"],
      ["a", "$2a$12$8NJH3LsPrANStV6XtBakCe", "$2a$12$8NJH3LsPrANStV6XtBakCez0cKHXVxmvxIlcz785vxAIZrihHZpeS"],
      ["a", "$2b$06$ehKGYiS4wt2HAr7KQXS5z.", "$2b$06$ehKGYiS4wt2HAr7KQXS5z.OaRjB4jHO7rBHJKlGXbqEH3QVJfO7iO"],
      ["a", "$2b$06$PWxFFHA3HiCD46TNOZh30e", "$2b$06$PWxFFHA3HiCD46TNOZh30eNto1hg5uM9tHBlI4q/b03SW/gGKUYk6"],
      ["a", "$2y$06$LUdD6/aD0e/UbnxVAVbvGu", "$2y$06$LUdD6/aD0e/UbnxVAVbvGuUmIoJ3l/OK94ThhadpMWwKC34LrGEey"],
      ["a", "$2y$06$eqgY.T2yloESMZxgp76deO", "$2y$06$eqgY.T2yloESMZxgp76deOROa7nzXDxbO0k.PJvuClTa.Vu1AuemG"],
      ["abc", "$2a$06$If6bvum7DFjUnE9p2uDeDu", "$2a$06$If6bvum7DFjUnE9p2uDeDu0YHzrHM6tf.iqN8.yx.jNN1ILEf7h0i"],
      ["abc", "$2a$08$Ro0CUfOqk6cXEKf3dyaM7O", "$2a$08$Ro0CUfOqk6cXEKf3dyaM7OhSCvnwM9s4wIX9JeLapehKK5YdLxKcm"],
      ["abc", "$2a$10$WvvTPHKwdBJ3uk0Z37EMR.", "$2a$10$WvvTPHKwdBJ3uk0Z37EMR.hLA2W6N9AEBhEgrAOljy2Ae5MtaSIUi"],
      ["abc", "$2a$12$EXRkfkdmXn2gzds2SSitu.", "$2a$12$EXRkfkdmXn2gzds2SSitu.MW9.gAVqa9eLS1//RYtYCmB1eLHg.9q"],
      ["abc", "$2b$06$5FyQoicpbox1xSHFfhhdXu", "$2b$06$5FyQoicpbox1xSHFfhhdXuR2oxLpO1rYsQh5RTkI/9.RIjtoF0/ta"],
      ["abc", "$2b$06$1kJyuho8MCVP3HHsjnRMkO", "$2b$06$1kJyuho8MCVP3HHsjnRMkO1nvCOaKTqLnjG2TX1lyMFbXH/aOkgc."],
      ["abc", "$2y$06$ACfku9dT6.H8VjdKb8nhlu", "$2y$06$ACfku9dT6.H8VjdKb8nhluaoBmhJyK7GfoNScEfOfrJffUxoUeCjK"],
      ["abc", "$2y$06$9JujYcoWPmifvFA3RUP90e", "$2y$06$9JujYcoWPmifvFA3RUP90e5rSEHAb5Ye6iv3.G9ikiHNv5cxjNEse"],
      ["abcdefghijklmnopqrstuvwxyz", "$2a$06$.rCVZVOThsIa97pEDOxvGu", "$2a$06$.rCVZVOThsIa97pEDOxvGuRRgzG64bvtJ0938xuqzv18d3ZpQhstC"],
      ["abcdefghijklmnopqrstuvwxyz", "$2a$08$aTsUwsyowQuzRrDqFflhge", "$2a$08$aTsUwsyowQuzRrDqFflhgekJ8d9/7Z3GV3UcgvzQW3J5zMyrTvlz."],
      ["abcdefghijklmnopqrstuvwxyz", "$2a$10$fVH8e28OQRj9tqiDXs1e1u", "$2a$10$fVH8e28OQRj9tqiDXs1e1uxpsjN0c7II7YPKXua2NAKYvM6iQk7dq"],
      ["abcdefghijklmnopqrstuvwxyz", "$2a$12$D4G5f18o7aMMfwasBL7Gpu", "$2a$12$D4G5f18o7aMMfwasBL7GpuQWuP3pkrZrOAnqP.bmezbMng.QwJ/pG"],
      ["abcdefghijklmnopqrstuvwxyz", "$2b$06$O8E89AQPj1zJQA05YvIAU.", "$2b$06$O8E89AQPj1zJQA05YvIAU.hMpj25BXri1bupl/Q7CJMlpLwZDNBoO"],
      ["abcdefghijklmnopqrstuvwxyz", "$2b$06$PDqIWr./o/P3EE/P.Q0A/u", "$2b$06$PDqIWr./o/P3EE/P.Q0A/uFg86WL/PXTbaW267TDALEwDylqk00Z."],
      ["abcdefghijklmnopqrstuvwxyz", "$2y$06$34MG90ZLah8/ZNr3ltlHCu", "$2y$06$34MG90ZLah8/ZNr3ltlHCuz6bachF8/3S5jTuzF1h2qg2cUk11sFW"],
      ["abcdefghijklmnopqrstuvwxyz", "$2y$06$AK.hSLfMyw706iEW24i68u", "$2y$06$AK.hSLfMyw706iEW24i68uKAc2yorPTrB0cimvjJHEBUrPkOq7VvG"],
      ["~!@#$%^&*()      ~!@#$%^&*()PNBFRD", "$2a$06$fPIsBO8qRqkjj273rfaOI.", "$2a$06$fPIsBO8qRqkjj273rfaOI.HtSV9jLDpTbZn782DC6/t7qT67P6FfO"],
      ["~!@#$%^&*()      ~!@#$%^&*()PNBFRD", "$2a$08$Eq2r4G/76Wv39MzSX262hu", "$2a$08$Eq2r4G/76Wv39MzSX262huzPz612MZiYHVUJe/OcOql2jo4.9UxTW"],
      ["~!@#$%^&*()      ~!@#$%^&*()PNBFRD", "$2a$10$LgfYWkbzEvQ4JakH7rOvHe", "$2a$10$LgfYWkbzEvQ4JakH7rOvHe0y8pHKF9OaFgwUZ2q7W2FFZmZzJYlfS"],
      ["~!@#$%^&*()      ~!@#$%^&*()PNBFRD", "$2a$12$WApznUOJfkEGSmYRfnkrPO", "$2a$12$WApznUOJfkEGSmYRfnkrPOr466oFDCaj4b6HY3EXGvfxm43seyhgC"],
      ["~!@#$%^&*()      ~!@#$%^&*()PNBFRD", "$2b$06$FGWA8OlY6RtQhXBXuCJ8Wu", "$2b$06$FGWA8OlY6RtQhXBXuCJ8WusVipRI15cWOgJK8MYpBHEkktMfbHRIG"],
      ["~!@#$%^&*()      ~!@#$%^&*()PNBFRD", "$2b$06$G6aYU7UhUEUDJBdTgq3CRe", "$2b$06$G6aYU7UhUEUDJBdTgq3CRekiopCN4O4sNitFXrf5NUscsVZj3a2r6"],
      ["~!@#$%^&*()      ~!@#$%^&*()PNBFRD", "$2y$06$sYDFHqOcXTjBgOsqC0WCKe", "$2y$06$sYDFHqOcXTjBgOsqC0WCKeMd3T1UhHuWQSxncLGtXDLMrcE6vFDti"],
      ["~!@#$%^&*()      ~!@#$%^&*()PNBFRD", "$2y$06$6Xm0gCw4g7ZNDCEp4yTise", "$2y$06$6Xm0gCw4g7ZNDCEp4yTisez0kSdpXEl66MvdxGidnmChIe8dFmMnq"]
    ]
    for secret, salt, test_vector in test_vectors
      expect(BCrypt::Engine.hash_secret(secret, salt)).to eql(test_vector)
    end
  end
end
