# frozen_string_literal: true

RSpec.describe Ogg::SyncState do
  subject(:sync) { described_class.new }

  after { sync.clear }

  describe ".new" do
    it "raises when native sync initialization fails" do
      allow(Ogg::Native).to receive(:ogg_sync_init).and_return(-1, 0)
      expect { described_class.new }.to raise_error(Ogg::SyncError, /ogg_sync_init/)
    end
  end

  describe "#initialize" do
    it "creates a new SyncState" do
      expect(sync).to be_a(described_class)
    end
  end

  describe "#write and #pageout" do
    it "returns nil when no complete page is available" do
      expect(sync.pageout).to be_nil
    end

    it "returns a Page when a complete page has been written" do
      stream = Ogg::StreamState.new(1)
      packet = Ogg::Packet.new(data: "test data", bos: true, granulepos: 0, packetno: 0)
      stream.packetin(packet)
      page = stream.flush
      expect(page).not_to be_nil

      sync.write(page.to_s)
      result = sync.pageout
      expect(result).to be_a(Ogg::Page)
      stream.clear
    end

    it "raises when ogg_sync_buffer returns null" do
      allow(Ogg::Native).to receive(:ogg_sync_buffer).and_return(FFI::Pointer::NULL)
      expect { sync.write("abc") }.to raise_error(Ogg::SyncError, /ogg_sync_buffer/)
    end

    it "raises typed corruption errors for unsynced data" do
      allow(Ogg::Native).to receive(:ogg_sync_pageout).and_return(-1)
      expect { sync.pageout }.to raise_error(Ogg::SyncCorruptDataError)
    end
  end

  describe "#reset" do
    it "resets the sync state" do
      expect { sync.reset }.not_to raise_error
    end
  end

  describe "#clear" do
    it "releases resources" do
      expect { sync.clear }.not_to raise_error
    end

    it "can be called multiple times safely" do
      sync.clear
      expect { sync.clear }.not_to raise_error
    end
  end

  describe "operations after #clear" do
    it "raises a released resource error" do
      sync.clear
      expect { sync.pageout }.to raise_error(Ogg::ReleasedResourceError)
    end
  end
end
