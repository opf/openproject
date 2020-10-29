class AWS
  module IAM
    # A self-signed test keypair. Generated using the command:
    # openssl req -new -newkey rsa:1024 -days 3650 -nodes -x509 -keyout server-private.key -out server-public.crt
    # NB: Amazon returns an error on extraneous linebreaks
    SERVER_CERT = %{-----BEGIN CERTIFICATE-----
MIIDQzCCAqygAwIBAgIJAJaZ8wH+19AtMA0GCSqGSIb3DQEBBQUAMHUxCzAJBgNV
BAYTAlVTMREwDwYDVQQIEwhOZXcgWW9yazERMA8GA1UEBxMITmV3IFlvcmsxHzAd
BgNVBAoTFkZvZyBUZXN0IFNuYWtlb2lsIENlcnQxHzAdBgNVBAsTFkZvZyBUZXN0
IFNuYWtlb2lsIENlcnQwHhcNMTEwNTA3MTc0MDU5WhcNMjEwNTA0MTc0MDU5WjB1
MQswCQYDVQQGEwJVUzERMA8GA1UECBMITmV3IFlvcmsxETAPBgNVBAcTCE5ldyBZ
b3JrMR8wHQYDVQQKExZGb2cgVGVzdCBTbmFrZW9pbCBDZXJ0MR8wHQYDVQQLExZG
b2cgVGVzdCBTbmFrZW9pbCBDZXJ0MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQC0CR76sovjdmpWRmEaf8XaG+nGe7czhpdLKkau2b16VtSjkPctxPL5U4vaMxQU
boLPr+9oL+9fSYN31VzDD4hyaeGoeI5fhnGeqk71kq5uHONBOQUMbZbBQ8PVd9Sd
k+y9JJ6E5fC+GhLL5I+y2DK7syBzyymq1Wi6rPp1XXF7AQIDAQABo4HaMIHXMB0G
A1UdDgQWBBRfqBkpU/jEV324748fq6GJM80iVTCBpwYDVR0jBIGfMIGcgBRfqBkp
U/jEV324748fq6GJM80iVaF5pHcwdTELMAkGA1UEBhMCVVMxETAPBgNVBAgTCE5l
dyBZb3JrMREwDwYDVQQHEwhOZXcgWW9yazEfMB0GA1UEChMWRm9nIFRlc3QgU25h
a2VvaWwgQ2VydDEfMB0GA1UECxMWRm9nIFRlc3QgU25ha2VvaWwgQ2VydIIJAJaZ
8wH+19AtMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAUV6NDdLHKNhl
ACtzLycIhlMTmDr0xBeIBx3lpgw2K0+4oefMS8Z17eeZPeNodxnz56juJm81BZwt
DF3qnnPyArLFx0HLB7wQdm9xYVIqQuLO+V6GRuOd+uSX//aDLDZhwbERf35hoyto
Jfk4gX/qwuRFNy0vjQeTzdvhB1igG/w=
-----END CERTIFICATE-----
    }
    # The public key for SERVER_CERT. Generated using the command:
    # openssl x509 -inform pem -in server-public.crt -pubkey -noout > server.pubkey
    SERVER_CERT_PUBLIC_KEY = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0CR76sovjdmpWRmEaf8XaG+nGe7czhpdLKkau2b16VtSjkPctxPL5U4vaMxQUboLPr+9oL+9fSYN31VzDD4hyaeGoeI5fhnGeqk71kq5uHONBOQUMbZbBQ8PVd9Sdk+y9JJ6E5fC+GhLL5I+y2DK7syBzyymq1Wi6rPp1XXF7AQIDAQAB"

    SERVER_CERT_PRIVATE_KEY = %{-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQC0CR76sovjdmpWRmEaf8XaG+nGe7czhpdLKkau2b16VtSjkPct
xPL5U4vaMxQUboLPr+9oL+9fSYN31VzDD4hyaeGoeI5fhnGeqk71kq5uHONBOQUM
bZbBQ8PVd9Sdk+y9JJ6E5fC+GhLL5I+y2DK7syBzyymq1Wi6rPp1XXF7AQIDAQAB
AoGANjjRBbwkeXs+h4Fm2W5GDmx9ufOkt3X/tvmilCKr+F6SaDjO2RAKBaFt62ea
0pR9/UMFnaFiPJaNa9fsuirBcwId+RizruEp+7FGziM9mC5kcE7WKZrXgGGnLtqg
4x5twVLArgp0ji7TA18q/74uTrI4az8H5iTY4n29ORlLmmkCQQDsGMuLEgGHgN5Y
1c9ax1DT/rUXKxnqsIrijRkgbiTncHAArFJ88c3yykWqGvYnSFwMS8DSWiPyPaAI
nNNlb/fPAkEAwzZ4CfvJ+OlE++rTPH9jemC89dnxC7EFGuWJmwdadnev8EYguvve
cdGdGttD7QsZKpcz5mDngOUghbVm8vBELwJAMHfOoVgq9DRicP5DuTEdyMeLSZxR
j7p6aJPqypuR++k7NQgrTvcc/nDD6G3shpf2PZf3l7dllb9M8TewtixMRQJBAIdX
c0AQtoYBTJePxiYyd8i32ypkkK83ar+sFoxKO9jYwD1IkZax2xZ0aoTdMindQPR7
Yjs+QiLmOHcbPqX+GHcCQERsSn0RjzKmKirDntseMB59BB/cEN32+gMDVsZuCfb+
fOy2ZavFl13afnhbh2/AjKeDhnb19x/uXjF7JCUtwpA=
-----END RSA PRIVATE KEY-----
    }

    # openssl pkcs8 -nocrypt -topk8 -in SERVER_CERT_PRIVATE_KEY.key -outform pem
    SERVER_CERT_PRIVATE_KEY_PKCS8 = %{-----BEGIN PRIVATE KEY-----
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBALQJHvqyi+N2alZG
YRp/xdob6cZ7tzOGl0sqRq7ZvXpW1KOQ9y3E8vlTi9ozFBRugs+v72gv719Jg3fV
XMMPiHJp4ah4jl+GcZ6qTvWSrm4c40E5BQxtlsFDw9V31J2T7L0knoTl8L4aEsvk
j7LYMruzIHPLKarVaLqs+nVdcXsBAgMBAAECgYA2ONEFvCR5ez6HgWbZbkYObH25
86S3df+2+aKUIqv4XpJoOM7ZEAoFoW3rZ5rSlH39QwWdoWI8lo1r1+y6KsFzAh35
GLOu4Sn7sUbOIz2YLmRwTtYpmteAYacu2qDjHm3BUsCuCnSOLtMDXyr/vi5Osjhr
PwfmJNjifb05GUuaaQJBAOwYy4sSAYeA3ljVz1rHUNP+tRcrGeqwiuKNGSBuJOdw
cACsUnzxzfLKRaoa9idIXAxLwNJaI/I9oAic02Vv988CQQDDNngJ+8n46UT76tM8
f2N6YLz12fELsQUa5YmbB1p2d6/wRiC6+95x0Z0a20PtCxkqlzPmYOeA5SCFtWby
8EQvAkAwd86hWCr0NGJw/kO5MR3Ix4tJnFGPunpok+rKm5H76Ts1CCtO9xz+cMPo
beyGl/Y9l/eXt2WVv0zxN7C2LExFAkEAh1dzQBC2hgFMl4/GJjJ3yLfbKmSQrzdq
v6wWjEo72NjAPUiRlrHbFnRqhN0yKd1A9HtiOz5CIuY4dxs+pf4YdwJARGxKfRGP
MqYqKsOe2x4wHn0EH9wQ3fb6AwNWxm4J9v587LZlq8WXXdp+eFuHb8CMp4OGdvX3
H+5eMXskJS3CkA==
-----END PRIVATE KEY-----
    }

    SERVER_CERT_PRIVATE_KEY_MISMATCHED = %{-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAyITMqYJMzkPMcaC+x0W2hnZVW99RXzLR8RYyD3xo2AotdJKx
1DXR4ryegAjsnAhJVwVtxqzPcBMq/XS0hNtWFfKzf+vMZl7uAqotGjURUV8SRQPA
8tT07MemD929xRSV2vTnVATiPn87vcu5igsZ01+Ewd6rGythmvcZD13vtZ4rx0c8
kQJV3ok/CkFaIgDR6Or1NZBCtcIVK9nvqAmYMp6S5mWUMIsl/1qYPerpefrSJjlk
J2+jyLp0LHarbzjkzzAdOkBRX1hPkk6cisBeQIpx35shLzfCe8U25XNqquP+ftcu
JZ0Wjw+C4pTIzfgdGXmGGtBFY13BwiJvd4/i2wIDAQABAoIBABk8XWWX+IKdFcXX
LSt3IpmZmvSNDniktLday8IXLjrCTSY2sBq9C0U159zFQsIAaPqCvGYcqZ65StfL
MEzoLdVlTiHzUy4vFFVRhYue0icjh/EXn9jv5ENIfSXSCmgbRyDfYZ25X5/t817X
nOo6q21mwBaGJ5KrywTtxEGi2OBKZrIbBrpJLhCXJc5xfuKT6DRa9X/OBSBiGKJP
V9wHcZJkPG1HnC8izvQ37kNN/NyYE+8AGdYXQVNbTHq/emNLbEbdcR3tpGZamM9Q
TwG5WsDPAnXnRsEEYvlVTOBI6DqdvkyBxM35iqd5aAc6i/Iu04Unfhhc5pAXmmIB
a22GHcECgYEA7OheVHDDP8quO2qZjqaTlMbMnXnrFXJ41llFMoivTW9EmlTl9dOC
fnkHEBcFCTPV0m6S2AQjt9QOgPqCFAq1r3J/xvEGBtl/UKnPRmjqXFgl0ENtGn5t
w9wj/CsOPD05KkXXtXP+MyLPRD6gAxiQCTnXjvsLuVfP+E9BO2EQXScCgYEA2K2x
QtcAAalrk3c0KzNVESzyFlf3ddEXThShVblSa7r6Ka9q9sxN/Xe2B+1oemPJm26G
PfqKgxdKX0R0jl4f5pRBWKoarzWtUge/su8rx/xzbY/1hFKVuimtc6oTeU5xsOTS
PVuCz4bxDTVhrbmKqbmMgqy17jfPA4BrF1FMRS0CgYBdMA4i4vQ6fIxKfOUIMsfs
hsJn01RAbHXRwu2wMgnayMDQgEKwjtFO1GaN0rA9bXFXQ/1pET/HiJdn7qIKJihP
aheO9rHrMdSdsx4AUTaWummtYUhiWobsuwRApeMEmQSKd0yhaI3+KVwkOQoSDbBi
oKkE6gUzk7IPt4UuSUD5kwKBgQCjo/IGr8dieegz08gDhF4PfalLdJ4ATaxTHMOH
sVFs6SY7Sy72Ou//qGRCcmsAW9KL35nkvw3S2Ukiz9lTGATxqC/93WIPxvMhy5Zc
dcLT43XtXdanW5OWqBlGDEFu0O6OERIyoqUVRC1Ss2kUwdbWPbq/id5Qjbd7RoYa
cxyt9QKBgF4bFLw1Iw2RBngQxIzoDbElEqme20FUyGGzyFQtxVwmwNr4OY5UzJzX
7G6diyzGrvRX81Yw616ppKJUJVr/zRc13K+eRXXKtNpGkf35B+1NDDjjWZpIHqgx
Xb9WSr07saxZQbxBPQyTlb0Q9Tu2djAq2/o/nYD1/50/fXUTuWMB
-----END RSA PRIVATE KEY-----
    }

    module Formats
      BASIC = {
        'RequestId' => String
      }

      USER = {
        'Arn'        => String,
        'Path'       => String,
        'UserId'     => String,
        'UserName'   => String,
      }

      CREATE_USER = BASIC.merge('User' => USER)

      GET_USER = BASIC.merge('User' => USER.merge('CreateDate' => Time))

      GET_CURRENT_USER = BASIC.merge(
        'User' => {
          'Arn'        => String,
          'UserId'     => String,
          'CreateDate' => Time
        }
      )

      LIST_USER = BASIC.merge(
        'Users' => [USER.merge('CreateDate' => Time)],
        'IsTruncated' => Fog::Boolean
      )

      GROUPS = BASIC.merge(
        'GroupsForUser' => [{
          'Arn'       => String,
          'GroupId'   => String,
          'GroupName' => String,
          'Path'      => String
        }],
        'IsTruncated' => Fog::Boolean
      )

      INSTANCE_PROFILE = {
        'Arn'                 => String,
        'CreateDate'          => Time,
        'InstanceProfileId'   => String,
        'InstanceProfileName' => String,
        'Path'                => String,
        'Roles'               => Array
      }

      INSTANCE_PROFILE_RESULT = BASIC.merge(
        'InstanceProfile' => INSTANCE_PROFILE
      )

      LIST_INSTANCE_PROFILE_RESULT = BASIC.merge(
        "IsTruncated" => Fog::Boolean,
        "InstanceProfiles" => [INSTANCE_PROFILE]
      )
    end
  end
end
