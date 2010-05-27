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
      
      def three_d_enrolled
        three_d_enrolled = @xml.root.get_elements('Response/OperationResponse/Enrolled').first
        three_d_enrolled.nil? ? nil : three_d_enrolled.text
      end
      
      def three_d_status
        three_d_status = @xml.root.get_elements('Response/ThreeDSecure/Status').first
        three_d_status.nil? ? nil : three_d_status.text
      end
            
      def three_d_html
        three_d_html = @xml.root.get_elements('Response/OperationResponse/Html').first
        three_d_html.nil? ? "Unspecified" : three_d_html.text
      end
      
      def pa_req
        pa_req = @xml.root.get_elements('Response/OperationResponse/PaReq').first
        pa_req.nil? ? nil : pa_req.text
      end
      
      def acs_url
        acs_url = @xml.root.get_elements('Response/OperationResponse/AcsUrl').first
        acs_url.nil? ? nil : acs_url.text
      end
      
      def md
        md = @xml.root.get_elements('Response/OperationResponse/MD').first || @xml.root.get_elements('Response/ThreeDSecure/MD').first
        md.nil? ? nil : md.text
      end
      
      def pa_res
        pa_res = @xml.root.get_elements('Response/ThreeDSecure/PaRes').first
        pa_res.nil? ? nil : pa_res.text
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
      
      def cvv_match
        cvv_match = @xml.root.get_elements('Response/OperationResponse/SecurityResponseSecurityCode').first
        cvv_match.nil? ? nil : cvv_match.text
      end
      
      def address_match
        address_match = @xml.root.get_elements('Response/OperationResponse/SecurityResponseAddress').first
        address_match.nil? ? nil : address_match.text
      end
      
      def postcode_match
        postcode_match = @xml.root.get_elements('Response/OperationResponse/SecurityResponsePostCode').first
        postcode_match.nil? ? nil : postcode_match.text
      end
    end
  end
end