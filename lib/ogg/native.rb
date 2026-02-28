# frozen_string_literal: true

module Ogg
  module Native
    extend FFI::Library
    ffi_lib ["libogg.so.0", "libogg.0.dylib", "libogg", "ogg"]

    # --- Structs ---

    class OggSyncState < FFI::Struct
      layout :data,         :pointer,
             :storage,      :int,
             :fill,         :int,
             :returned,     :int,
             :unsynced,     :int,
             :headerbytes,  :int,
             :bodybytes,    :int
    end

    class OggStreamState < FFI::Struct
      layout :body_data,       :pointer,
             :body_storage,    :long,
             :body_fill,       :long,
             :body_returned,   :long,
             :lacing_vals,     :pointer,
             :granule_vals,    :pointer,
             :lacing_storage,  :long,
             :lacing_fill,     :long,
             :lacing_packet,   :long,
             :lacing_returned, :long,
             :header,          [:uchar, 282],
             :header_fill,     :int,
             :e_o_s,           :int,
             :b_o_s,           :int,
             :serialno,        :long,
             :pageno,          :long,
             :packetno,        :int64,
             :granulepos,      :int64
    end

    class OggPage < FFI::Struct
      layout :header,     :pointer,
             :header_len, :long,
             :body,       :pointer,
             :body_len,   :long
    end

    class OggPacket < FFI::Struct
      layout :packet,     :pointer,
             :bytes,      :long,
             :b_o_s,      :long,
             :e_o_s,      :long,
             :granulepos, :int64,
             :packetno,   :int64
    end

    # --- Sync API ---

    attach_function :ogg_sync_init,     [:pointer],              :int
    attach_function :ogg_sync_clear,    [:pointer],              :int
    attach_function :ogg_sync_reset,    [:pointer],              :int
    attach_function :ogg_sync_buffer,   [:pointer, :long],       :pointer
    attach_function :ogg_sync_wrote,    [:pointer, :long],       :int
    attach_function :ogg_sync_pageout,  [:pointer, :pointer],    :int
    attach_function :ogg_sync_pageseek, [:pointer, :pointer],    :long

    # --- Stream API ---

    attach_function :ogg_stream_init,           [:pointer, :int],              :int
    attach_function :ogg_stream_clear,          [:pointer],                    :int
    attach_function :ogg_stream_reset,          [:pointer],                    :int
    attach_function :ogg_stream_reset_serialno, [:pointer, :int],             :int
    attach_function :ogg_stream_packetin,       [:pointer, :pointer],          :int
    attach_function :ogg_stream_pageout,        [:pointer, :pointer],          :int
    attach_function :ogg_stream_pageout_fill,   [:pointer, :pointer, :int],   :int
    attach_function :ogg_stream_flush,          [:pointer, :pointer],          :int
    attach_function :ogg_stream_flush_fill,     [:pointer, :pointer, :int],   :int
    attach_function :ogg_stream_pagein,         [:pointer, :pointer],          :int
    attach_function :ogg_stream_packetout,      [:pointer, :pointer],          :int
    attach_function :ogg_stream_packetpeek,     [:pointer, :pointer],          :int
    attach_function :ogg_stream_eos,            [:pointer],                    :int

    # --- Page API ---

    attach_function :ogg_page_version,       [:pointer], :int
    attach_function :ogg_page_continued,     [:pointer], :int
    attach_function :ogg_page_bos,           [:pointer], :int
    attach_function :ogg_page_eos,           [:pointer], :int
    attach_function :ogg_page_granulepos,    [:pointer], :int64
    attach_function :ogg_page_serialno,      [:pointer], :int
    attach_function :ogg_page_pageno,        [:pointer], :long
    attach_function :ogg_page_packets,       [:pointer], :int
    attach_function :ogg_page_checksum_set,  [:pointer], :void

    # --- Packet API ---

    attach_function :ogg_packet_clear, [:pointer], :void
  end
end
