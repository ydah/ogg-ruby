# frozen_string_literal: true

RSpec.describe Ogg::Page do
  let(:stream) { Ogg::StreamState.new(123) }
  let(:page) do
    packet = Ogg::Packet.new(data: "page test data", bos: true, granulepos: 100, packetno: 0)
    stream.packetin(packet)
    stream.flush
  end

  after { stream.clear }

  describe "#version" do
    it "returns the page version" do
      expect(page.version).to eq(0)
    end
  end

  describe "#bos?" do
    it "returns true for the first page" do
      expect(page.bos?).to be true
    end
  end

  describe "#eos?" do
    it "returns false for a non-final page" do
      expect(page.eos?).to be false
    end

    it "returns true for the last page" do
      eos_packet = Ogg::Packet.new(data: "end", eos: true, granulepos: 200, packetno: 1)
      stream.packetin(eos_packet)
      eos_page = stream.flush
      expect(eos_page.eos?).to be true
    end
  end

  describe "#continued?" do
    it "returns false for a non-continued page" do
      expect(page.continued?).to be false
    end
  end

  describe "#serialno" do
    it "returns the stream serial number" do
      expect(page.serialno).to eq(123)
    end
  end

  describe "#pageno" do
    it "returns the page number" do
      expect(page.pageno).to be >= 0
    end
  end

  describe "#granulepos" do
    it "returns the granule position" do
      expect(page.granulepos).to be_a(Integer)
    end
  end

  describe "#packets" do
    it "returns the number of packets in the page" do
      expect(page.packets).to be >= 1
    end
  end

  describe "#header_data" do
    it "returns header bytes" do
      data = page.header_data
      expect(data).to be_a(String)
      expect(data.encoding).to eq(Encoding::BINARY)
      expect(data.bytesize).to be > 0
    end

    it "raises after owner stream is cleared" do
      produced_page = page
      stream.clear
      expect { produced_page.header_data }.to raise_error(Ogg::ReleasedResourceError)
    end
  end

  describe "#body_data" do
    it "returns body bytes" do
      data = page.body_data
      expect(data).to be_a(String)
      expect(data.bytesize).to be > 0
    end
  end

  describe "#to_s" do
    it "returns header + body concatenated" do
      expect(page.to_s).to eq(page.header_data + page.body_data)
    end
  end
end
