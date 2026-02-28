# frozen_string_literal: true

module Ogg
  class Page
    attr_reader :native

    def initialize(native_page = nil, owner: nil)
      @owner = owner
      if native_page
        @ptr = native_page
        @native = native_page.is_a?(Native::OggPage) ? native_page : Native::OggPage.new(native_page)
      else
        @ptr = FFI::MemoryPointer.new(Native::OggPage.size)
        @native = Native::OggPage.new(@ptr)
      end
    end

    def version
      ensure_owner_active!
      Native.ogg_page_version(@ptr)
    end

    def continued?
      ensure_owner_active!
      Native.ogg_page_continued(@ptr) != 0
    end

    def bos?
      ensure_owner_active!
      Native.ogg_page_bos(@ptr) != 0
    end

    def eos?
      ensure_owner_active!
      Native.ogg_page_eos(@ptr) != 0
    end

    def granulepos
      ensure_owner_active!
      Native.ogg_page_granulepos(@ptr)
    end

    def serialno
      ensure_owner_active!
      Native.ogg_page_serialno(@ptr)
    end

    def pageno
      ensure_owner_active!
      Native.ogg_page_pageno(@ptr)
    end

    def packets
      ensure_owner_active!
      Native.ogg_page_packets(@ptr)
    end

    def header_data
      read_segment(:header, :header_len)
    end

    def body_data
      read_segment(:body, :body_len)
    end

    def to_s
      header_data + body_data
    end

    private

    def read_segment(pointer_field, length_field)
      ensure_owner_active!
      length = @native[length_field]
      raise Error, "#{length_field} cannot be negative" if length.negative?
      return +"".b if length.zero?

      pointer = @native[pointer_field]
      raise Error, "#{pointer_field} is null while #{length_field}=#{length}" if pointer.null?

      pointer.read_bytes(length)
    end

    def ensure_owner_active!
      return unless @owner&.cleared?

      raise ReleasedResourceError, "cannot read page data after owner state is cleared"
    end
  end
end
