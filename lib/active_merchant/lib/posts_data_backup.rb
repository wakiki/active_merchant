module ActiveMerchant #:nodoc:
  module PostsData  #:nodoc:

    def self.included(base)
      base.superclass_delegating_accessor :ssl_strict
      base.ssl_strict = true

      base.class_attribute :retry_safe
      base.retry_safe = false

      base.superclass_delegating_accessor :open_timeout
      base.open_timeout = 60

      base.superclass_delegating_accessor :read_timeout
      base.read_timeout = 60

      base.superclass_delegating_accessor :logger
      base.superclass_delegating_accessor :wiredump_device
    end

    def ssl_get(endpoint, headers={})
      ssl_request(:get, endpoint, nil, headers)
    end

    def ssl_post(endpoint, data, headers = {})
      ssl_request(:post, endpoint, data, headers)
    end

    def socket_request(host, port, data)
      retry_exceptions do
        begin
          connection = TCPsocket.open host, port

          connection.write data
          response = connection.read
          connection.close

          response
        rescue EOFError => e
          raise ConnectionError, "The remote server dropped the connection"
        rescue Errno::ECONNRESET => e
          raise ConnectionError, "The remote server reset the connection"
        rescue Errno::ECONNREFUSED => e
          raise RetriableConnectionError, "The remote server (#{host}:#{port}) refused the connection"
        rescue Timeout::Error, Errno::ETIMEDOUT => e
          raise ConnectionError, "The connection to the remote server timed out"
        end
      end
    end

    private

    def retry_exceptions
      retries = MAX_RETRIES
      begin
        yield
      rescue RetriableConnectionError => e
        retries -= 1
        retry unless retries.zero?
        raise ConnectionError, e.message
      rescue ConnectionError
        retries -= 1
        retry if retry_safe && !retries.zero?
        raise
      end
    end

    # original active_merchant version
    def ssl_request(method, endpoint, data, headers = {})
      connection = Connection.new(endpoint)
      connection.open_timeout = open_timeout
      connection.read_timeout = read_timeout
      connection.retry_safe   = retry_safe
      connection.verify_peer  = ssl_strict
      connection.logger       = logger
      connection.tag          = self.class.name
      connection.wiredump_device = wiredump_device

      connection.pem          = @options[:pem] if @options
      connection.pem_password = @options[:pem_password] if @options

      connection.request(method, data, headers)
    end

    # Dan's version
    def ssl_request(method, url, data, headers = {})
      if method == :post
        # Ruby 1.8.4 doesn't automatically set this header
        headers['Content-Type'] ||= "application/x-www-form-urlencoded"
      end

      uri   = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = self.class.open_timeout
      http.read_timeout = self.class.read_timeout

      if uri.scheme == "https"
        http.use_ssl = true

        if ssl_strict
          http.verify_mode    = OpenSSL::SSL::VERIFY_PEER
          http.ca_file        = File.dirname(__FILE__) + '/../../certs/cacert.pem'
        else
          http.verify_mode    = OpenSSL::SSL::VERIFY_NONE
        end

        if @options && !@options[:pem].blank?
          http.cert           = OpenSSL::X509::Certificate.new(@options[:pem])

          if pem_password
            raise ArgumentError, "The private key requires a password" if @options[:pem_password].blank?
            http.key            = OpenSSL::PKey::RSA.new(@options[:pem], @options[:pem_password])
          else
            http.key            = OpenSSL::PKey::RSA.new(@options[:pem])
          end
        end
      end

      retry_exceptions do
        begin
          case method
          when :get
            http.get(uri.request_uri, headers).body
          when :post
            http.post(uri.request_uri, data, headers).body
          end
        rescue EOFError => e
          raise ConnectionError, "The remote server dropped the connection"
        rescue Errno::ECONNRESET => e
          raise ConnectionError, "The remote server reset the connection"
        rescue Errno::ECONNREFUSED => e
          raise RetriableConnectionError, "The remote server refused the connection"
        rescue Timeout::Error, Errno::ETIMEDOUT => e
          raise ConnectionError, "The connection to the remote server timed out"
        end
      end
    end

  end
end
