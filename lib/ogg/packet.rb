# frozen_string_literal: true

module Ogg
  class Packet
    attr_reader :native

    def initialize(data: nil, bos: false, eos: false, granulepos: 0, packetno: 0, owner: nil)
      @owner = owner
      @ptr = FFI::MemoryPointer.new(Native::OggPacket.size)
      @native = Native::OggPacket.new(@ptr)

      if data
        @data_ptr = FFI::MemoryPointer.new(:uint8, data.bytesize)
        @data_ptr.put_bytes(0, data)
        @native[:packet] = @data_ptr
        @native[:bytes] = data.bytesize
        @native[:b_o_s] = bos ? 1 : 0
        @native[:e_o_s] = eos ? 1 : 0
        @native[:granulepos] = granulepos
        @native[:packetno] = packetno
      end
    end

    def data
      ensure_owner_active!
      length = @native[:bytes]
      raise Error, "packet bytes cannot be negative" if length.negative?
      return +"".b if length.zero?

      pointer = @native[:packet]
      raise Error, "packet pointer is null while bytes=#{length}" if pointer.null?

      pointer.read_bytes(length)
    end

    def bytes
      @native[:bytes]
    end

    def bos?
      @native[:b_o_s] != 0
    end

    def eos?
      @native[:e_o_s] != 0
    end

    def granulepos
      @native[:granulepos]
    end

    def packetno
      @native[:packetno]
    end

    private

    def ensure_owner_active!
      return unless @owner&.cleared?

      raise ReleasedResourceError, "cannot read packet data after owner state is cleared"
    end
  end
end
