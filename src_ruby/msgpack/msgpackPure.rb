# coding: utf-8


#他のMessagePackライブラリと同一に使えるようにするため
#元ソース（https://github.com/nayutaya/msgpack-pure）に以下のmoduleを追加。

module MessagePack
  def self.pack(value)
    MessagePackPure.pack(value)
  end
  def self.unpack(binary)
    MessagePackPure.unpack(binary)
  end
end


require "stringio"

module MessagePackPure
  VERSION = "0.0.2"
end


module MessagePackPure
  def self.pack(value)
    io = StringIO.new
    packer = Packer.new(io)
    packer.write(value)
    return io.string
  end

  def self.unpack(binary)
    io = StringIO.new(binary, "r")
    unpacker = Unpacker.new(io)
    return unpacker.read
  end
end


# MessagePack format specification
# http://msgpack.sourceforge.jp/spec

module MessagePackPure
  class Packer
  end
end

class MessagePackPure::Packer
  def initialize(io)
    @io = io
  end

  attr_reader :io

  def write(value)
    case value
    when Integer    then self.write_integer(value)
    when NilClass   then self.write_nil
    when TrueClass  then self.write_true
    when FalseClass then self.write_false
    when Float      then self.write_float(value)
    when String     then self.write_string(value)
    when Array      then self.write_array(value)
    when Hash       then self.write_hash(value)
    else raise("unknown type")
    end

    return @io
  end

  protected

  def write_integer(num)
    case num
    when (-0x20..0x7F)
      # positive fixnum, negative fixnum
      @io.write(self.pack_int8(num))
    when (0x00..0xFF)
      # uint8
      @io.write("\xCC")
      @io.write(self.pack_uint8(num))
    when (-0x80..0x7F)
      # int8
      @io.write("\xD0")
      @io.write(self.pack_int8(num))
    when (0x0000..0xFFFF)
      # uint16
      @io.write("\xCD")
      @io.write(self.pack_uint16(num))
    when (-0x8000..0x7FFF)
      # int16
      @io.write("\xD1")
      @io.write(self.pack_int16(num))
    when (0x00000000..0xFFFFFFFF)
      # uint32
      @io.write("\xCE")
      @io.write(self.pack_uint32(num))
    when (-0x80000000..0x7FFFFFFF)
      # int32
      @io.write("\xD2")
      @io.write(self.pack_int32(num))
    when (0x0000000000000000..0xFFFFFFFFFFFFFFFF)
      # uint64
      @io.write("\xCF")
      @io.write(self.pack_uint64(num))
    when (-0x8000000000000000..0x7FFFFFFFFFFFFFFF)
      # int64
      @io.write("\xD3")
      @io.write(self.pack_int64(num))
    else
      raise("invalid integer")
    end
  end

  def write_nil
    @io.write("\xC0")
  end

  def write_true
    @io.write("\xC3")
  end

  def write_false
    @io.write("\xC2")
  end

  def write_float(value)
    @io.write("\xCB")
    @io.write(self.pack_double(value))
  end

  def write_string(value)
    case value.size
    when (0x00..0x1F)
      # fixraw
      @io.write(self.pack_uint8(0b10100000 + value.size))
      @io.write(value)
    when (0x0000..0xFFFF)
      # raw16
      @io.write("\xDA")
      @io.write(self.pack_uint16(value.size))
      @io.write(value)
    when (0x00000000..0xFFFFFFFF)
      # raw32
      @io.write("\xDB")
      @io.write(self.pack_uint32(value.size))
      @io.write(value)
    else
      raise("invalid length")
    end
  end

  def write_array(value)
    case value.size
    when (0x00..0x0F)
      # fixarray
      @io.write(self.pack_uint8(0b10010000 + value.size))
    when (0x0000..0xFFFF)
      # array16
      @io.write("\xDC")
      @io.write(self.pack_uint16(value.size))
    when (0x00000000..0xFFFFFFFF)
      # array32
      @io.write("\xDD")
      @io.write(self.pack_uint32(value.size))
    else
      raise("invalid length")
    end

    value.each { |item|
      self.write(item)
    }
  end

  def write_hash(value)
    case value.size
    when (0x00..0x0F)
      # fixmap
      @io.write(self.pack_uint8(0b10000000 + value.size))
    when (0x0000..0xFFFF)
      # map16
      @io.write("\xDE")
      @io.write(self.pack_uint16(value.size))
    when (0x00000000..0xFFFFFFFF)
      # map32
      @io.write("\xDF")
      @io.write(self.pack_uint32(value.size))
    else
      raise("invalid length")
    end

    value.sort_by { |key, value| key }.each { |key, value|
      self.write(key)
      self.write(value)
    }
  end

  def pack_uint8(value)
    return [value].pack("C")
  end

  def pack_int8(value)
    return [value].pack("c")
  end

  def pack_uint16(value)
    return [value].pack("n")
  end

  def pack_int16(value)
    value += (2 ** 16) if value < 0
    return self.pack_uint16(value)
  end

  def pack_uint32(value)
    return [value].pack("N")
  end

  def pack_int32(value)
    value += (2 ** 32) if value < 0
    return self.pack_uint32(value)
  end

  def pack_uint64(value)
    high = (value >> 32)
    low  = (value & 0xFFFFFFFF)
    return self.pack_uint32(high) + self.pack_uint32(low)
  end

  def pack_int64(value)
    value += (2 ** 64) if value < 0
    return self.pack_uint64(value)
  end

  def pack_double(value)
    return [value].pack("G")
  end
end



# MessagePack format specification
# http://msgpack.sourceforge.jp/spec

module MessagePackPure
  class Unpacker
  end
end

class MessagePackPure::Unpacker
  def initialize(io)
    @io = io
  end

  attr_reader :io

  def read
    type = self.unpack_uint8

    case
    when (type & 0b10000000) == 0b00000000 # positive fixnum
      return type
    when (type & 0b11100000) == 0b11100000 # negative fixnum
      return (type & 0b00011111) - (2 ** 5)
    when (type & 0b11100000) == 0b10100000 # fixraw
      size = (type & 0b00011111)
      return @io.read(size)
    when (type & 0b11110000) == 0b10010000 # fixarray
      size = (type & 0b00001111)
      return self.read_array(size)
    when (type & 0b11110000) == 0b10000000 # fixmap
      size = (type & 0b00001111)
      return self.read_hash(size)
    end

    case type
    when 0xC0 # nil
      return nil
    when 0xC2 # false
      return false
    when 0xC3 # true
      return true
    when 0xCA # float
      return self.unpack_float
    when 0xCB # double
      return self.unpack_double
    when 0xCC # uint8
      return self.unpack_uint8
    when 0xCD # uint16
      return self.unpack_uint16
    when 0xCE # uint32
      return self.unpack_uint32
    when 0xCF # uint64
      return self.unpack_uint64
    when 0xD0 # int8
      return self.unpack_int8
    when 0xD1 # int16
      return self.unpack_int16
    when 0xD2 # int32
      return self.unpack_int32
    when 0xD3 # int64
      return self.unpack_int64
    when 0xDA # raw16
      size = self.unpack_uint16
      return @io.read(size)
    when 0xDB # raw32
      size = self.unpack_uint32
      return @io.read(size)
    when 0xDC # array16
      size = self.unpack_uint16
      return self.read_array(size)
    when 0xDD # array32
      size = self.unpack_uint32
      return self.read_array(size)
    when 0xDE # map16
      size = self.unpack_uint16
      return self.read_hash(size)
    when 0xDF # map32
      size = self.unpack_uint32
      return self.read_hash(size)
    else
      raise("Unknown Type -- #{'0x%02X' % type}")
    end
  end

  def read_array(size)
    result = []
    size.times { result << self.read }
    return result
  end

  def read_hash(size)
    result = {}
    size.times { |i| result[self.read] = self.read }
    return result
  end

  def unpack_uint8
    return @io.read(1).unpack("C")[0]
  end

  def unpack_int8
    return @io.read(1).unpack("c")[0]
  end

  def unpack_uint16
    return @io.read(2).unpack("n")[0]
  end

  def unpack_int16
    num = self.unpack_uint16
    return (num < 2 ** 15 ? num : num - (2 ** 16))
  end

  def unpack_uint32
    return @io.read(4).unpack("N")[0]
  end

  def unpack_int32
    num = self.unpack_uint32
    return (num < 2 ** 31 ? num : num - (2 ** 32))
  end

  def unpack_uint64
    high = self.unpack_uint32
    low  = self.unpack_uint32
    return (high << 32) + low
  end

  def unpack_int64
    num = self.unpack_uint64
    return (num < 2 ** 63 ? num : num - (2 ** 64))
  end

  def unpack_float
    return @io.read(4).unpack("g")[0]
  end

  def unpack_double
    return @io.read(8).unpack("G")[0]
  end
end
