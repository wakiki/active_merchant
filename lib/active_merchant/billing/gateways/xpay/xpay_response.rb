module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class XpayResponse
      def error?
        @xml.root.get_elements('Response/OperationResponse/Result').first.text == '0'
      end

      def success?
        @xml.root.get_elements('Response/OperationResponse/Result').first.text == '1'
      end
  
      def declined?
        @xml.root.get_elements('Response/OperationResponse/Result').first.text == '2'
      end
      
      def transaction_reference
        ref = @xml.root.get_elements('Response/OperationResponse/TransactionReference').first
        ref.nil? ? "Unspecified" : ref.text
      end
      
      def auth_code
        code = @xml.root.get_elements('Response/OperationResponse/AuthCode').first
        code.nil? ? "Unspecified" : code.text
      end
      
      def transaction_verifier
        verifier = @xml.root.get_elements('Response/OperationResponse/TransactionVerifier').first
        verifier.nil? ? "Unspecified" : verifier.text
      end
      
      def initialize(xml_response)
        @xml = REXML::Document.new xml_response
      end
      
      def to_xml
        @xml.to_s
      end
      
      def to_s
        if success?
          'The transaction was processed successfully.'
        elsif declined?
          'The transaction was declined by the card issuer.'
        else
          @xml.root.get_elements('Response/OperationResponse/Message').first.text
        end
      end
      
      def message
        self.to_s
      end
    end
  end
end