import "unittest" =~ [=> unittest]

exports (main, Base64)


def BASE64_PAD :Char := '='
def alphabet :DeepFrozen := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

object Base64 as DeepFrozen:
    "Base64 codec as per RFC 4648"

    to encode(_msg :Bytes):
        var msg := _msg
        var leftbits := 0
        var leftchar := 0
        var encoded_msg :Bytes := [].diverge()
        var this_char := 0

        while (msg.size() > 0):
            leftchar := leftchar << 8
            if (leftchar == 0):
                leftchar := msg[0]
            msg := msg.slice(1)
            leftbits += 8

            while (leftbits >= 6):
                def this_char := (leftchar >> (leftbits - 6)) & 0x3f
                leftbits -= 6
                def c := alphabet[this_char]
                encoded_msg.push(alphabet[this_char])

        if (leftbits == 2):
            def chr_idx := (leftchar & ('\x03'.asInteger())) << 4
            encoded_msg.push(alphabet[chr_idx])
            encoded_msg.push(BASE64_PAD)
            encoded_msg.push(BASE64_PAD)
        else if (leftbits == 4):
            def chr_idx := (leftchar & ('\x0f'.asInteger())) << 2
            encoded_msg.push(alphabet[chr_idx])
            encoded_msg.push(BASE64_PAD)

        return encoded_msg

    to decode(msg :Bytes):
        return msg


def test_b64_encode(assert):
    def msg := b`b`
    def encoded := Base64.encode(msg)
    def correctly_encoded := b`Yg==`

    assert.equal(encoded, correctly_encoded)

def test_b64_decode(assert):
    def msg := b`Yg==`
    def decoded := Base64.decode(msg)
    def correctly_decoded := b`b`

    assert.equal(decoded, correctly_decoded)


unittest([
    test_b64_encode,
    test_b64_decode
])

def main(argv) as DeepFrozen:
    traceln("Encoding \"33\"")
    traceln(Base64.encode(b`33`))
