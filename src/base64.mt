import "unittest" =~ [=> unittest]

exports (main, Base64)


def BASE64_PAD :Int := '='.asInteger()
def b64Alphabet :DeepFrozen := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
def table_b2a_base64 :DeepFrozen := [
    -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1,
    -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1,
    -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,62, -1,-1,-1,63,
    52,53,54,55, 56,57,58,59, 60,61,-1,-1, -1, 0,-1,-1, # Note PAD->0
    -1, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,-1, -1,-1,-1,-1,
    -1,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,-1, -1,-1,-1,-1
]

def find_valid(_msg, _len, _num) as DeepFrozen:
    traceln(`Find Valid, msg size: ``$_msg.size()```)
    var msg := _msg
    var len := _len
    var num := _num
    var ret :Int := -1
    var c :Int := -1
    var b64val :Int := 0
    def sf := 0x7f

    while ((len > 0) && (ret == -1)):
        c := msg[0]
        def _c_and_sf :Char := '\x00' + (c & sf)
        b64val := b64Alphabet.indexOf(`$_c_and_sf`)
        if ( ((c <= sf) && (b64val != -1))):
            if (num == 0):
                ret := c
            num -= 1
        len -= 1
        if (len > 0):
            msg := msg.slice(1)

    traceln(`Find Valid, msg size: $msg.size()`)
    return ret


object Base64 as DeepFrozen:
    "Base64 codec as per RFC 4648"

    to encode(_msg :Bytes):
        var msg := _msg
        var leftbits := 0
        var leftchar := 0
        var encoded_msg := [].diverge()
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
                def chr :Int := (b64Alphabet[this_char]).asInteger()
                encoded_msg.push(chr)

        if (leftbits == 2):
            def chr_idx := (leftchar & 0x03) << 4
            def chr :Int := (b64Alphabet[chr_idx]).asInteger()
            encoded_msg.push(chr)
            encoded_msg.push(BASE64_PAD)
            encoded_msg.push(BASE64_PAD)
        else if (leftbits == 4):
            def chr_idx := (leftchar & 0x0f) << 2
            def chr :Int := (b64Alphabet[chr_idx]).asInteger()
            encoded_msg.push(chr)
            encoded_msg.push(BASE64_PAD)

        return encoded_msg.snapshot()

    to decode(_msg :Bytes):
        var msg := _msg
        var decoded := [].diverge()
        var leftbits := 0
        var this_char := 0
        var leftchar := 0
        var quad_pos :Int := 0
        def skip_chars := [
            0x7f, '\n'.asInteger(), '\r'.asInteger(), ' '.asInteger()]

        while (msg.size() > 0):
            this_char := msg[0]
            traceln(`START LOOP: $this_char`)

            # Skip Newlines, spaces, and 0x7f
            if (skip_chars.contains(this_char)):
                msg := msg.slice(1)
                continue

            # Handle padding (= characters)
            if (this_char == BASE64_PAD):
                if ((quad_pos < 2) || ((quad_pos == 2) && (find_valid(msg, msg.size(), 1) != BASE64_PAD))):
                    # Skip over '='
                    msg := msg.slice(1)
                    continue
                else:
                    leftbits := 0
                    break

            this_char := table_b2a_base64[this_char]
            def x := '\x00' + this_char
            traceln(`This char: $this_char == $x`)
            if (this_char == -1):
                msg := msg.slice(1)
                continue

            quad_pos := ((quad_pos + 1) & 0x03)
            def t := leftchar << 6

            if (t == 0):
                leftchar := this_char
            else:
                leftchar := t
            leftbits += 6
            traceln(`Leftbits: $leftbits`)

            if (leftbits >= 8):
                leftbits -= 8
                decoded.push(
                    ((leftchar >> leftbits) & 0xff)
                )
                def one_and_one := ((1 << leftbits) - 1)
                leftchar &= one_and_one

            # Move forward in the data
            msg := msg.slice(1)

        if (leftbits != 0):
            throw(`Invalid Padding: $leftbits`)

        return decoded.snapshot()


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
