# encoding: utf-8

class RawNetCapture < StringIO
  attr_reader :transactions

  def initialize
    super
    reset
  end

  def received(data)
    @transactions[@transaction_index] << [:received, data]
  end

  def sent(data)
    if @transactions[@transaction_index].last && (@transactions[@transaction_index].last[0] == :received)
      @transaction_index += 1
      @transactions[@transaction_index] = []
    end

    @transactions[@transaction_index] << [:sent, data]
  end

  def reset
    @transaction_index = 0
    @transactions = [[]]
  end
end

class RawHTTPCapture < StringIO
  attr_reader :raw_received, :raw_sent

  def initialize
    super
    reset
  end

  def reset
    @raw_received = StringIO.new
    @raw_sent = StringIO.new
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
      s = @rbuf.slice!(0, len)
      if @debug_output
        @debug_output << %Q[-> #{s.dump}\n]
        @debug_output.received(s) if @debug_output.respond_to?(:received)
      end
      s
    end

    def write0(str)
      if @debug_output
        @debug_output << str.dump
        @debug_output.sent(str) if @debug_output.respond_to?(:sent)
      end
      len = @io.write(str)
      @written_bytes += len
      len
    end
  end
end
