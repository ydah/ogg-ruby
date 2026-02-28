# frozen_string_literal: true

require "ffi"
require_relative "ogg/version"
require_relative "ogg/native"
require_relative "ogg/page"
require_relative "ogg/packet"
require_relative "ogg/sync_state"
require_relative "ogg/stream_state"

module Ogg
  class Error < StandardError; end
  class ReleasedResourceError < Error; end
  class CorruptDataError < Error; end
  class SyncError < Error; end
  class SyncCorruptDataError < SyncError; end
  class StreamError < Error; end
  class StreamCorruptDataError < StreamError; end
end
