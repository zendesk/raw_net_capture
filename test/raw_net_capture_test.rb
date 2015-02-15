# encoding: utf-8
require File.expand_path '../helper', __FILE__

require 'net/https'
require 'uri'

class RawNetCaptureTest < MiniTest::Test
  describe RawNetCapture do
    before do
      capture = RawNetCapture.new

      uri = URI.parse("http://www.google.com/")
      http = Net::HTTP.new(uri.host, uri.port)
      http.set_debug_output capture
      http.get(uri.request_uri)

      @raw_sent = capture.transactions.first.select { |x| x[0] == :sent }.map { |x| x[1] }.join
      @raw_received = capture.transactions.first.select { |x| x[0] == :received }.map { |x| x[1] }.join
    end

    it "captures raw HTTP request and response" do
      assert_match /\AGET \/ HTTP\/1.1.*Host: www.google.com.*\z/m, @raw_sent
      assert_match /\AHTTP\/1.1 200 OK.*\z/m, @raw_received
    end
  end

  describe RawHTTPCapture do
    describe "when there is no redirection" do
      before do
        @capture = RawHTTPCapture.new

        uri = URI.parse("https://www.google.com/")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.set_debug_output @capture
        http.get(uri.request_uri)

      end

      it "captures raw HTTP request and response" do
        assert_match /\AGET \/ HTTP\/1.1.*Host: www.google.com.*\z/m, @capture.transactions.first[:sent].string
        assert_match /\AHTTP\/1.1 200 OK.*\z/m, @capture.transactions.first[:received].string
      end
    end

    describe "#headers" do
      before do
        @capture = RawHTTPCapture.new
        @capture.received "HTTP/1.1 200 OK\r\n"
        @capture.received "Date: Sun, 25 Jan 2015 11:23:31 GMT\r\n"
        @capture.received "Content-Type: text/html; charset=ISO-8859-1\r\n"
        @capture.received "Connection: close\r\n\r\n"
        @capture.received "<html>\r\n"
        @capture.received "<head><title>Document Title</title></head>\r\n"
        @capture.received "<body>This is some body text.</body>\r\n"
        @capture.received "</html>\r\n"

        transaction = @capture.transactions.first
        @headers = RawHTTPCapture.headers(transaction)
      end

      it "removes HTTP response body" do
        assert @headers.length < @capture.transactions.first[:received].string.length
        assert @headers.start_with?('HTTP/1.1 200 OK')
        assert @headers.end_with?("Connection: close\r\n\r\n")
      end
    end

    describe "when redirection occurs" do
      before do
        @capture = RawHTTPCapture.new

        uri = URI.parse("https://vkmita.zendesk.com/")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.set_debug_output @capture
        response = http.get(uri.request_uri)

        uri = URI.parse(response.header["location"])
        http.get(uri.request_uri)
      end

      it "captures both transactions" do
        assert @capture.transactions.first[:received].string.start_with?("HTTP/1.1 301 Moved Permanently")
        assert @capture.transactions.last[:received].string.start_with?("HTTP/1.1 200 OK")
      end
    end
  end
end
