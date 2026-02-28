# frozen_string_literal: true

RSpec.describe Ogg::Packet do
  describe "encoding constructor" do
    subject(:packet) do
      described_class.new(data: "hello world", bos: true, eos: false, granulepos: 42, packetno: 7)
    end

    it "stores the packet data" do
      expect(packet.data).to eq("hello world")
    end

    it "returns the correct byte count" do
      expect(packet.bytes).to eq(11)
    end

    it "reports bos correctly" do
      expect(packet.bos?).to be true
    end

    it "reports eos correctly" do
      expect(packet.eos?).to be false
    end

    it "returns granulepos" do
      expect(packet.granulepos).to eq(42)
    end

    it "returns packetno" do
      expect(packet.packetno).to eq(7)
    end
  end

  describe "decoding constructor" do
    subject(:packet) { described_class.new }

    it "creates a packet with zero bytes" do
      expect(packet.bytes).to eq(0)
    end

    it "reports bos as false" do
      expect(packet.bos?).to be false
    end

    it "reports eos as false" do
      expect(packet.eos?).to be false
    end

    it "raises when bytes are set but packet pointer is null" do
      packet.native[:bytes] = 3
      expect { packet.data }.to raise_error(Ogg::Error, /packet pointer is null/)
    end
  end

  describe "decoded packet lifetime" do
    it "raises after owner stream is cleared" do
      encoder = Ogg::StreamState.new(2026)
      sync = Ogg::SyncState.new
      decoder = Ogg::StreamState.new(2026)

      encoder.packetin(described_class.new(data: "payload", bos: true, eos: true, granulepos: 0, packetno: 0))
      encoded_page = encoder.flush
      sync.write(encoded_page.to_s)

      decoded_page = sync.pageout
      decoder.pagein(decoded_page)
      decoded_packet = decoder.packetout

      decoder.clear
      expect { decoded_packet.data }.to raise_error(Ogg::ReleasedResourceError)
    ensure
      encoder.clear unless encoder.cleared?
      sync.clear unless sync.cleared?
      decoder.clear unless decoder.cleared?
    end
  end
end
