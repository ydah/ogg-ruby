# frozen_string_literal: true

RSpec.describe Ogg::StreamState do
  subject(:stream) { described_class.new(42) }

  after { stream.clear }

  describe ".new" do
    it "raises when native stream initialization fails" do
      allow(Ogg::Native).to receive(:ogg_stream_init).and_call_original
      allow(Ogg::Native).to receive(:ogg_stream_init).with(kind_of(FFI::Pointer), 99).and_return(-1)
      expect { described_class.new(99) }.to raise_error(Ogg::StreamError, /ogg_stream_init/)
    end
  end

  describe "#initialize" do
    it "creates a new StreamState with the given serial number" do
      expect(stream).to be_a(described_class)
      expect(stream.serialno).to eq(42)
    end
  end

  describe "#packetin and #pageout" do
    it "returns nil when no page is ready" do
      expect(stream.pageout).to be_nil
    end

    it "produces a page after enough packets are added" do
      packet = Ogg::Packet.new(data: "hello", bos: true, granulepos: 0, packetno: 0)
      stream.packetin(packet)
      page = stream.flush
      expect(page).to be_a(Ogg::Page)
    end
  end

  describe "#flush" do
    it "forces a page out even if not full" do
      packet = Ogg::Packet.new(data: "x" * 100, bos: true, granulepos: 0, packetno: 0)
      stream.packetin(packet)
      page = stream.flush
      expect(page).to be_a(Ogg::Page)
    end

    it "returns nil when no data is available" do
      expect(stream.flush).to be_nil
    end
  end

  describe "#eos?" do
    it "returns false initially" do
      expect(stream.eos?).to be false
    end

    it "returns true after an eos packet is flushed" do
      packet = Ogg::Packet.new(data: "end", bos: true, eos: true, granulepos: 0, packetno: 0)
      stream.packetin(packet)
      stream.flush
      expect(stream.eos?).to be true
    end
  end

  describe "#packetout" do
    it "raises a typed corruption error when native reports a hole" do
      allow(Ogg::Native).to receive(:ogg_stream_packetout).and_return(-1)
      expect { stream.packetout }.to raise_error(Ogg::StreamCorruptDataError)
    end
  end

  describe "#packetpeek" do
    it "raises a typed corruption error when native reports a hole" do
      allow(Ogg::Native).to receive(:ogg_stream_packetpeek).and_return(-1)
      expect { stream.packetpeek }.to raise_error(Ogg::StreamCorruptDataError)
    end
  end

  describe "#reset" do
    it "resets the stream state" do
      expect { stream.reset }.not_to raise_error
    end
  end

  describe "#clear" do
    it "releases resources" do
      expect { stream.clear }.not_to raise_error
    end

    it "can be called multiple times safely" do
      stream.clear
      expect { stream.clear }.not_to raise_error
    end
  end

  describe "operations after #clear" do
    it "raises a released resource error" do
      stream.clear
      expect { stream.pageout }.to raise_error(Ogg::ReleasedResourceError)
    end
  end
end
