# ogg-ruby

Ruby FFI bindings for [libogg](https://xiph.org/ogg/), the OGG container format library.

## Requirements

- Ruby 3.1+
- libogg installed on your system

### Installing libogg

**macOS:**

```bash
brew install libogg
```

**Debian/Ubuntu:**

```bash
sudo apt-get install libogg-dev
```

**Fedora/RHEL:**

```bash
sudo dnf install libogg-devel
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ogg-ruby"
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install ogg-ruby
```

## Usage

### Encoding (Packet → StreamState → Page)

```ruby
require "ogg"

stream = Ogg::StreamState.new(1) # serial number

# Add packets to the stream
packet = Ogg::Packet.new(data: "Hello, OGG!", bos: true, granulepos: 0, packetno: 0)
stream.packetin(packet)

packet2 = Ogg::Packet.new(data: "More data", eos: true, granulepos: 1, packetno: 1)
stream.packetin(packet2)

# Extract pages
pages = []
while (page = stream.flush)
  pages << page.to_s
end

stream.clear
```

### Decoding (SyncState → Page → StreamState → Packet)

```ruby
require "ogg"

sync = Ogg::SyncState.new

# Write encoded data into sync
sync.write(encoded_page_data)

# Extract pages
while (page = sync.pageout)
  # Create a stream decoder with the same serial number
  stream = Ogg::StreamState.new(page.serialno)
  stream.pagein(page)

  # Extract packets
  while (packet = stream.packetout)
    puts packet.data
  end

  stream.clear
end

sync.clear
```

## Thread Safety

libogg functions are not thread-safe. Do not share `SyncState` or `StreamState` objects across threads without external synchronization.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
