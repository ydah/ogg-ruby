# frozen_string_literal: true

module Ogg
  class SyncState
    def initialize
      @ptr = FFI::MemoryPointer.new(Native::OggSyncState.size)
      result = Native.ogg_sync_init(@ptr)
      raise SyncError, "ogg_sync_init failed with status #{result}" unless result == 0

      @clear_state = [false]
      ObjectSpace.define_finalizer(self, self.class.finalizer_for(@ptr, @clear_state))
    end

    def write(data)
      ensure_active!
      buffer = Native.ogg_sync_buffer(@ptr, data.bytesize)
      raise SyncError, "ogg_sync_buffer returned null" if buffer.null?

      buffer.put_bytes(0, data)
      result = Native.ogg_sync_wrote(@ptr, data.bytesize)
      raise SyncError, "ogg_sync_wrote failed with status #{result}" unless result == 0
    end

    def pageout
      ensure_active!
      page = Page.new(owner: self)
      result = Native.ogg_sync_pageout(@ptr, page.native)
      case result
      when 1 then page
      when 0 then nil
      when -1 then raise SyncCorruptDataError, "ogg_sync_pageout detected unsynced/corrupt data"
      else raise SyncError, "ogg_sync_pageout returned unexpected status #{result}"
      end
    end

    def reset
      ensure_active!
      result = Native.ogg_sync_reset(@ptr)
      raise SyncError, "ogg_sync_reset failed with status #{result}" unless result == 0
    end

    def clear
      return if cleared?

      result = Native.ogg_sync_clear(@ptr)
      raise SyncError, "ogg_sync_clear failed with status #{result}" unless result == 0

      @clear_state[0] = true
    end

    def cleared?
      @clear_state[0]
    end

    def self.finalizer_for(ptr, clear_state)
      proc do
        Native.ogg_sync_clear(ptr) unless clear_state[0]
      end
    end

    private

    def ensure_active!
      return unless cleared?

      raise ReleasedResourceError, "sync state has been cleared"
    end
  end
end
