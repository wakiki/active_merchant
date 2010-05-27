require File.dirname(__FILE__) + '/../../test_helper'

class XpayTest < Test::Unit::TestCase
  def setup
    @site_reference = "testvocalix14298"
    XpayGateway.site_reference = @site_reference
    XpayGateway.certificate_path = "/Users/Steve/work/insoshi/config/xpay/#{@site_reference}.pem"
    XpayGateway.port = "5444"
    XpayGateway.host = "localhost"
    @gateway = XpayGateway.new(
                 :site_reference => @site_reference,
                 :certificate_path => "/Users/Steve/work/insoshi/config/xpay/#{@site_reference}.pem",
                 :debug => true
               )

    @credit_card = credit_card
    @amount = 100
    
    @options = { 
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end
  
  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of 
    assert_success response
    
    # Replace with authorization number from the successful response
    assert_equal '', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  private
  
  # Place raw successful response from gateway here
  def successful_purchase_response
  end
  
  # Place raw failed response from gateway here
  def failed_purcahse_response
  end
end
