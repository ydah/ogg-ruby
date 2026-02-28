# frozen_string_literal: true

RSpec.describe "Roundtrip encoding/decoding" do
  it "encodes packets into pages and decodes them back to the original data" do
    serialno = 12_345
    original_data = ["first packet", "second packet", "third and final packet"]

    # --- Encode ---
    encoder = Ogg::StreamState.new(serialno)

    original_data.each_with_index do |data, i|
      packet = Ogg::Packet.new(
        data: data,
        bos: i == 0,
        eos: i == original_data.size - 1,
        granulepos: i + 1,
        packetno: i
      )
      encoder.packetin(packet)
    end

    pages = []
    while (page = encoder.flush)
      pages << page.to_s
    end

    expect(pages).not_to be_empty

    # --- Decode ---
    sync = Ogg::SyncState.new
    decoder = Ogg::StreamState.new(serialno)

    decoded_data = []

    pages.each do |page_bytes|
      sync.write(page_bytes)

      while (page = sync.pageout)
        expect(page.serialno).to eq(serialno)
        decoder.pagein(page)

        while (packet = decoder.packetout)
          decoded_data << packet.data
        end
      end
    end

    expect(decoded_data).to eq(original_data)

    encoder.clear
    decoder.clear
    sync.clear
  end

  it "handles multiple streams with different serial numbers" do
    data_stream1 = ["stream1 packet1", "stream1 packet2"]
    data_stream2 = ["stream2 packet1", "stream2 packet2"]

    # Encode both streams
    enc1 = Ogg::StreamState.new(100)
    enc2 = Ogg::StreamState.new(200)

    all_pages = []

    data_stream1.each_with_index do |data, i|
      enc1.packetin(Ogg::Packet.new(data: data, bos: i == 0, eos: i == data_stream1.size - 1,
                                    granulepos: i, packetno: i))
    end
    while (page = enc1.flush)
      all_pages << page.to_s
    end

    data_stream2.each_with_index do |data, i|
      enc2.packetin(Ogg::Packet.new(data: data, bos: i == 0, eos: i == data_stream2.size - 1,
                                    granulepos: i, packetno: i))
    end
    while (page = enc2.flush)
      all_pages << page.to_s
    end

    # Decode
    sync = Ogg::SyncState.new
    dec1 = Ogg::StreamState.new(100)
    dec2 = Ogg::StreamState.new(200)

    decoded1 = []
    decoded2 = []

    all_pages.each do |page_bytes|
      sync.write(page_bytes)

      while (page = sync.pageout)
        case page.serialno
        when 100
          dec1.pagein(page)
          while (pkt = dec1.packetout)
            decoded1 << pkt.data
          end
        when 200
          dec2.pagein(page)
          while (pkt = dec2.packetout)
            decoded2 << pkt.data
          end
        end
      end
    end

    expect(decoded1).to eq(data_stream1)
    expect(decoded2).to eq(data_stream2)

    [enc1, enc2, dec1, dec2].each(&:clear)
    sync.clear
  end
end
