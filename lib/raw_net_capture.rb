# encoding: utf-8

class RawNetCapture < StringIO
  attr_reader :raw_traffic

  def initialize
    super
    reset
  end

  def received(data)
    @raw_traffic << [:received, data]
  end

  def sent(data)
    @raw_traffic << [:sent, data]
  end

  def reset
    @raw_traffic = []
  end
end

class RawHTTPCapture < StringIO
  def initialize
    super
    reset
  end

  def reset
    @raw_received = StringIO.new
    @raw_sent = StringIO.new
  end

  def raw_sent
    @raw_sent
  end

  def raw_received
    @raw_received
  end

  def received(data)
    @raw_received << data
  end

  def sent(data)
    @raw_sent << data
  end

  def headers
    separator = "\r\n\r\n"
    raw_string = @raw_received.string

    if headers_end_index = raw_string.index(separator)
      raw_string[0...(headers_end_index + separator.length)]
    else
      raw_string
    end
  end
end

module Net
  class BufferedIO
    private

    def rbuf_consume(len)
      @rbuf.slice!(0, len).tap do |string|
        if @debug_output
          @debug_output << %Q[-> #{string.dump}\n]
          @debug_output.received(string +  "\r\n\r\n") if @debug_output.respond_to?(:received)
        end
      end
    end

    def write0(str)
      if @debug_output
        @debug_output << str.dump
        @debug_output.sent(str + "\r\n\r\n") if @debug_output.respond_to?(:sent)
      end

      @io.write(str).tap { |len| @written_bytes += len }
    end
  end
end
