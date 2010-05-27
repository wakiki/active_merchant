require File.dirname(__FILE__) + '/../../test_helper'

class RemoteXpayTest < Test::Unit::TestCase

  def setup
    @gateway = XpayGateway.new
    
    @gateway.site_reference = "testvocalix14298"
    @gateway.certificate_path = File.dirname(__FILE__) + '/../../testvocalix14298.pem'
    @gateway.host = 'localhost'
    @gateway.port = 5444
    
    @amount = 100
    @credit_cards = {
      :visa             => credit_card('4111111111111111'),
      :mastercard       => credit_card('5111111111111118', :type => :master),
      :uk_maestro1      => credit_card('6759050000000005', :type => :maestro, :issue_number => '1'),
      :uk_maestro2      => credit_card('6759000000000018', :type => :maestro),
      :solo             => credit_card('676770676770676775', :type => :solo, :issue_number => '1'),
      :visa_delta       => credit_card('4659010000000005', :type => :delta),
      :visa_electron    => credit_card('49174917491749174', :type => :electron),
      :visa_purchasing  => credit_card('4484000000000007', :type => :purchasing),
      :mastercard_debit => credit_card('5573470000000001', :type => :master),
      :american_express => credit_card('377737773777380', :type => :american_express)
    }
    @declined_credit_cards = {
      :visa             => credit_card('4242424242424242'),
      :mastercard       => credit_card('5111111111111142', :type => :master),
      :uk_maestro1      => credit_card('6759050000000062', :type => :maestro, :issue_number => '1'),
      :uk_maestro2      => credit_card('6759000000000042', :type => :maestro),
      :solo             => credit_card('676770676770676882', :type => :solo, :issue_number => '1'),
      :visa_delta       => credit_card('4659010000000062', :type => :delta),
      :visa_purchasing  => credit_card('4484000000000072', :type => :purchasing),
      :mastercard_debit => credit_card('5573470000000092', :type => :master),
      :american_express => credit_card('377737773777422', :type => :american_express)
    }
    
    @three_d_cards = {
      :visa_not_in_scheme_accept         => credit_card('4111111111111111'),             
      :visa_not_in_scheme_decline        => credit_card('4242424242424242'),             
      :visa_in_scheme_accept             => credit_card('4111111111111160'),             
      :visa_in_scheme_decline            => credit_card('4111111111111392'),             
      :visa_unknown_response_accept      => credit_card('4111111111111178'),
      :master_not_in_scheme_accept       => credit_card('5111111111111118', :type => :master),
      :master_not_in_scheme_decline      => credit_card('5111111111111142', :type => :master),
      :master_in_scheme_accept           => credit_card('5111111111111126', :type => :master),
      :master_in_scheme_decline          => credit_card('5111111111111282', :type => :master),
      :master_unknown_response_accept    => credit_card('5111111111111134', :type => :master),
      :uk_maestro_1_in_scheme_accept     => credit_card('6759000000000018', :type => :maestro),
      :uk_maestro_1_in_scheme_decline    => credit_card('6759000000000042', :type => :maestro),
      :uk_maestro_2_in_scheme_accept     => credit_card('6759050000000021', :type => :maestro, :issue_number => '1'),
      :uk_maestro_not_in_scheme_accept   => credit_card('6759050000000005', :type => :maestro, :issue_number => '1'),
      :uk_maestro_not_in_scheme_decline  => credit_card('6759050000000062', :type => :maestro, :issue_number => '1'),
      :international_maestro_in_scheme_accept => credit_card('5000000000000009', :type => :maestro),
      :international_maestro_in_scheme_decline => credit_card('5000000000000017', :type => :maestro)
    }
    
    @options = { 
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase',
      :currency => 'GBP'
    }

    @responses = {}
  end
  
  def test_successful_purchase
    @credit_cards.each do |type, credit_card|
      assert response = @gateway.purchase(@amount, credit_card, @options)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
    end
  end
  
  def test_unsuccessful_purchase
    @declined_credit_cards.each do |type, credit_card|
      assert response = @gateway.purchase(@amount, credit_card, @options)
      assert_failure response
      assert_equal "The transaction was declined by the card issuer.", response.message
    end
  end
  
  def test_authorize_and_capture
    @responses = {}
    @credit_cards.each do |type, credit_card|
      assert response = @gateway.authorize(@amount, credit_card, @options)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
      @responses[type] = response
    end
    sleep 5 # Needs to wait before checking results - if you get failures, try increasing this
    @credit_cards.each do |type, credit_card|    
      assert response = @gateway.capture(@amount, @responses[type].transaction_reference)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
    end
  end
  
  def test_unsuccessful_capture
    assert response = @gateway.capture(@amount, '')
    assert_failure response
    assert_equal "(5100) Missing TransactionReference", response.message
    assert response = @gateway.capture(@amount, '123')
    assert_failure response
    assert_equal "(3100) Invalid ParentTransactionReference", response.message
  end
  
  def test_authorize_and_void
    @credit_cards.each do |type, credit_card|
      assert response = @gateway.authorize(@amount, credit_card, @options)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
      @responses[type] = response
    end
    sleep 5 # Needs to wait before checking results - if you get failures, try increasing this
    @credit_cards.each do |type, credit_card|
      identification = {
        :transaction_reference => @responses[type].transaction_reference,
        :transaction_verifier => @responses[type].transaction_verifier
      }
      assert response = @gateway.void(identification)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
    end
  end
  
  def test_authorize_and_capture_and_refund
    @credit_cards.each do |type, credit_card|
      assert response = @gateway.authorize(@amount, credit_card, @options)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
      @responses[type] = response
    end
    sleep 5 # Needs to wait before checking results - if you get failures, try increasing this
    @credit_cards.each do |type, credit_card|
      identification = {
        :transaction_reference => @responses[type].transaction_reference,
        :transaction_verifier => @responses[type].transaction_verifier
      }
      assert response = @gateway.capture(@amount, @responses[type].transaction_reference)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
    end
    @credit_cards.each do |type, credit_card|
      identification = {
        :transaction_reference => @responses[type].transaction_reference,
        :transaction_verifier => @responses[type].transaction_verifier
      }
      assert response = @gateway.credit(@amount, identification)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
    end
  end
  
  def test_purchase_and_repeat
    @credit_cards.each do |type, credit_card|
      assert response = @gateway.purchase(@amount, credit_card, @options)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
      @responses[type] = response
    end
    @credit_cards.each do |type, credit_card|
      identification = {
        :transaction_reference => @responses[type].transaction_reference,
        :transaction_verifier => @responses[type].transaction_verifier
      }
      assert response = @gateway.repeat(@amount, identification, @options)
      assert_success response
      assert_equal "The transaction was processed successfully.", response.message
    end    
  end
  
  def test_three_d_card_query
    @options[:term_url] = "http://localhost:3000/credit_cards/xxx/three_d_complete?credit_card_transaction_id=xxx"
    @options[:merchant_name] = "app_name"
    @three_d_cards.each do |type, credit_card|
      assert response = @gateway.three_d_card_query(@amount, credit_card, @options)
      # puts type unless response.success?
      # puts response.to_xml
      assert_success response
    end  
  end
  
  # three_d_complete will be tested in selenium as requires browser interaction
  
end