# encoding: utf-8

class RawNetCapture < StringIO
  attr_reader :transactions

  def initialize
    super
    reset
  end

  def received(data)
    @transactions.last << [:received, data]
  end

  def sent(data)
    if @transactions.last.last && (@transactions.last.last[0] == :received)
      @transactions << []
    end

    @transactions.last << [:sent, data]
  end

  def reset
    @transactions = [[]]
  end
end

class RawHTTPCapture < StringIO
  attr_reader :transactions

  def self.headers(transaction)
    separator = "\r\n\r\n"
    raw_string = transaction[:received].string
    if headers_end_index = raw_string.index(separator)
      raw_string[0...(headers_end_index + separator.length)]
    else
      raw_string
    end
  end

  def initialize
    super
    reset
  end

  def reset
    @transactions = [{
      :received => StringIO.new,
      :sent => StringIO.new
    }]
  end

  def received(data)
    @getting_response = true
    transactions.last[:received] << data
  end

  def sent(data)
    if @getting_response
      @getting_response = false
      @transactions << {
        :received => StringIO.new,
        :sent => StringIO.new
      }
    end

    transactions.last[:sent] << data
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
