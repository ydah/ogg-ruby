# frozen_string_literal: true

module Ogg
  class StreamState
    attr_reader :serialno

    def initialize(serialno)
      @serialno = serialno
      @ptr = FFI::MemoryPointer.new(Native::OggStreamState.size)
      result = Native.ogg_stream_init(@ptr, serialno)
      raise StreamError, "ogg_stream_init failed with status #{result}" unless result == 0

      @clear_state = [false]
      ObjectSpace.define_finalizer(self, self.class.finalizer_for(@ptr, @clear_state))
    end

    def packetin(packet)
      ensure_active!
      result = Native.ogg_stream_packetin(@ptr, packet.native)
      raise StreamError, "ogg_stream_packetin failed with status #{result}" unless result == 0
    end

    def pageout
      ensure_active!
      page = Page.new(owner: self)
      result = Native.ogg_stream_pageout(@ptr, page.native)
      case result
      when 1 then page
      when 0 then nil
      when -1 then raise StreamCorruptDataError, "ogg_stream_pageout detected stream corruption"
      else raise StreamError, "ogg_stream_pageout returned unexpected status #{result}"
      end
    end

    def flush
      ensure_active!
      page = Page.new(owner: self)
      result = Native.ogg_stream_flush(@ptr, page.native)
      case result
      when 1 then page
      when 0 then nil
      when -1 then raise StreamCorruptDataError, "ogg_stream_flush detected stream corruption"
      else raise StreamError, "ogg_stream_flush returned unexpected status #{result}"
      end
    end

    def pagein(page)
      ensure_active!
      result = Native.ogg_stream_pagein(@ptr, page.native)
      case result
      when 0 then nil
      when -1 then raise StreamCorruptDataError, "ogg_stream_pagein detected stream corruption"
      else raise StreamError, "ogg_stream_pagein failed with status #{result}"
      end
    end

    def packetout
      ensure_active!
      packet = Packet.new(owner: self)
      result = Native.ogg_stream_packetout(@ptr, packet.native)
      case result
      when 1 then packet
      when 0 then nil
      when -1 then raise StreamCorruptDataError, "ogg_stream_packetout detected a hole in the stream"
      else raise StreamError, "ogg_stream_packetout returned unexpected status #{result}"
      end
    end

    def packetpeek
      ensure_active!
      packet = Packet.new(owner: self)
      result = Native.ogg_stream_packetpeek(@ptr, packet.native)
      case result
      when 1 then packet
      when 0 then nil
      when -1 then raise StreamCorruptDataError, "ogg_stream_packetpeek detected a hole in the stream"
      else raise StreamError, "ogg_stream_packetpeek returned unexpected status #{result}"
      end
    end

    def eos?
      ensure_active!
      result = Native.ogg_stream_eos(@ptr)
      case result
      when 0 then false
      when 1 then true
      else
        raise StreamError, "ogg_stream_eos returned unexpected status #{result}"
      end
    end

    def reset
      ensure_active!
      result = Native.ogg_stream_reset(@ptr)
      raise StreamError, "ogg_stream_reset failed with status #{result}" unless result == 0
    end

    def reset_serialno(serialno)
      ensure_active!
      result = Native.ogg_stream_reset_serialno(@ptr, serialno)
      raise StreamError, "ogg_stream_reset_serialno failed with status #{result}" unless result == 0

      @serialno = serialno
    end

    def clear
      return if cleared?

      result = Native.ogg_stream_clear(@ptr)
      raise StreamError, "ogg_stream_clear failed with status #{result}" unless result == 0

      @clear_state[0] = true
    end

    def cleared?
      @clear_state[0]
    end

    def self.finalizer_for(ptr, clear_state)
      proc do
        Native.ogg_stream_clear(ptr) unless clear_state[0]
      end
    end

    private

    def ensure_active!
      return unless cleared?

      raise ReleasedResourceError, "stream state has been cleared"
    end
  end
end
