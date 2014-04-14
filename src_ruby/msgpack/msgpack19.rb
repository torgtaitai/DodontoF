# encoding: utf-8

module MessagePack
  def self.pack(obj)

  end

  def self.unpack(bytes)
    Decoder.new(bytes).next
  end

  class Decoder
    def initialize(bytes)
      @bytes = bytes
      @offset = 0
    end

    def next
      consume_next
    end

    private

    DECODINGS = []
    DECODINGS[0xc0] = lambda { |d| nil }
    DECODINGS[0xc2] = lambda { |d| false }
    DECODINGS[0xc3] = lambda { |d| true }
    DECODINGS[0xc4] = lambda { |d| d.consume_string(d.consume_byte, Encoding::BINARY) }
    DECODINGS[0xc5] = lambda { |d| d.consume_string(d.consume_int16, Encoding::BINARY) }
    DECODINGS[0xc6] = lambda { |d| d.consume_string(d.consume_int32, Encoding::BINARY) }
    DECODINGS[0xca] = lambda { |d| d.consume_float }
    DECODINGS[0xcb] = lambda { |d| d.consume_double }
    DECODINGS[0xcc] = lambda { |d| d.consume_byte }
    DECODINGS[0xcd] = lambda { |d| d.consume_int16 }
    DECODINGS[0xce] = lambda { |d| d.consume_int32 }
    DECODINGS[0xcf] = lambda { |d| d.consume_int64 }
    DECODINGS[0xd0] = lambda { |d| d.consume_byte - 0x100 }
    DECODINGS[0xd1] = lambda { |d| d.consume_int16 - 0x10000 }
    DECODINGS[0xd2] = lambda { |d| d.consume_int32 - 0x100000000 }
    DECODINGS[0xd3] = lambda { |d| d.consume_int64 - 0x10000000000000000 }
    DECODINGS[0xd9] = lambda { |d| d.consume_string(d.consume_byte) }
    DECODINGS[0xda] = lambda { |d| d.consume_string(d.consume_int16) }
    DECODINGS[0xdb] = lambda { |d| d.consume_string(d.consume_int32) }
    DECODINGS[0xdc] = lambda { |d| d.consume_array(d.consume_int16) }
    DECODINGS[0xdd] = lambda { |d| d.consume_array(d.consume_int32) }
    DECODINGS[0xde] = lambda { |d| Hash[*d.consume_array(d.consume_int16 * 2)] }
    DECODINGS[0xdf] = lambda { |d| Hash[*d.consume_array(d.consume_int32 * 2)] }

    FLOAT_FMT = 'g'.freeze
    DOUBLE_FMT = 'G'.freeze

    public

    def consume_byte
      b = @bytes.getbyte(@offset)
      @offset += 1
      b
    end

    def consume_int16
      (consume_byte << 8) | consume_byte
    end

    def consume_int32
      (consume_byte << 24) | (consume_byte << 16) | (consume_byte << 8) | consume_byte
    end

    def consume_int64
      n  = (consume_byte << 56)
      n |= (consume_byte << 48)
      n |= (consume_byte << 40)
      n |= (consume_byte << 32)
      n |= (consume_byte << 24)
      n |= (consume_byte << 16)
      n |= (consume_byte << 8)
      n |=  consume_byte
      n
    end

    def consume_float
      f = @bytes[@offset, 4].unpack(FLOAT_FMT).first
      @offset += 4
      f
    end

    def consume_double
      d = @bytes[@offset, 8].unpack(DOUBLE_FMT).first
      @offset += 8
      d
    end

    def consume_string(size, encoding=Encoding::UTF_8)
      s = @bytes[@offset, size]
      s.force_encoding(encoding)
      @offset += size
      s
    end

    def consume_array(size)
      Array.new(size) { consume_next }
    end

    def consume_next
      b = consume_byte
      if (method = DECODINGS[b])
        method.call(self)
      elsif b <= 0b01111111
        b
      elsif b & 0b11100000 == 0b11100000
        b - 0x100
      elsif b & 0b11100000 == 0b10100000
        size = b & 0b00011111
        consume_string(size)
      elsif b & 0b11110000 == 0b10010000
        size = b & 0b00001111
        consume_array(size)
      elsif b & 0b11110000 == 0b10000000
        size = b & 0b00001111
        Hash[*consume_array(size * 2)]
      end
    end
  end
end
