import "unittest" =~ [=> unittest]

exports (main, Base64)


def BASE64_PAD :Int := '='.asInteger()
def table_b2a_base64 :DeepFrozen := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
def table_a2b_base64 :DeepFrozen := [
    -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1,
    -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1,
    -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,62, -1,-1,-1,63,
    52,53,54,55, 56,57,58,59, 60,61,-1,-1, -1, 0,-1,-1, # Note PAD->0
    -1, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,-1, -1,-1,-1,-1,
    -1,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,-1, -1,-1,-1,-1
]

def find_valid(msg :Bytes, num :Int) as DeepFrozen:
    var ret := -1
    var b64val := 0

    for c in (msg):
        b64val := table_a2b_base64[(c & 0x7f)]
        if ((c != -1) && (b64val != -1)):
            if (num == 0):
                ret := c

    return ret


object Base64 as DeepFrozen:
    "Base64 codec as per RFC 4648"

    to encode(msg :Bytes):
        var encoded_msg := b``
        var leftchar := 0
        var leftbits := 0
        var this_char := 0

        for c in (msg):
            leftchar := (leftchar << 8) | c
            leftbits += 8

            while (leftbits >= 6):
                this_char := (leftchar >> (leftbits - 6)) & 0x3f
                leftbits -= 6
                encoded_msg += table_b2a_base64.get(this_char).asInteger()

        if (leftbits == 2):
            def tbl_pos := (leftchar & 0x3) << 4
            encoded_msg += table_b2a_base64[tbl_pos].asInteger()
            encoded_msg += BASE64_PAD
            encoded_msg += BASE64_PAD
        else if (leftbits == 4):
            def tbl_pos := (leftchar & 0xf) << 2
            encoded_msg += table_b2a_base64[tbl_pos].asInteger()
            encoded_msg += BASE64_PAD

        return encoded_msg.asList().snapshot()

    to decode(msg :Bytes):
        var decoded_msg := b``
        var leftbits := 0
        var leftchar := 0
        var quad_pos := 0
        var this_char := 0

        for ascii_byte in (msg):
            if (ascii_byte > 0x7f):
                continue

            if (ascii_byte == BASE64_PAD):
                if ((quad_pos < 2) ||
                    ((quad_pos == 2) &&
                    (find_valid(msg, 1) != BASE64_PAD))):
                    continue
                else:
                    leftbits := 0
                    break

            this_char := table_a2b_base64[ascii_byte]
            if (this_char == -1):
                continue

            quad_pos := (quad_pos + 1) & 0x03
            leftchar := (leftchar << 6) | this_char
            leftbits += 6

            if (leftbits >= 8):
                leftbits -= 8
                decoded_msg += (leftchar >> leftbits) & 0xff
                leftchar &= (1 << leftbits) - 1

        if (leftbits != 0):
            throw(b`Incorrect padding.`)

        return decoded_msg.asList().snapshot()


def test_b64_encode(assert):
    def msg := b`b`
    def encoded := Base64.encode(msg)
    def correctly_encoded := b`Yg==`.asList()

    assert.equal(encoded, correctly_encoded)

def test_b64_decode(assert):
    def msg := b`Yg==`
    def decoded := Base64.decode(msg)
    def correctly_decoded := b`b`.asList()

    assert.equal(decoded, correctly_decoded)


unittest([
    test_b64_encode,
    test_b64_decode
])

def main(argv) as DeepFrozen:
    traceln("Encoding \"33\"")
    traceln(Base64.encode(b`33`))
