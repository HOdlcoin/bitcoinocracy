require 'net/http'
class BitcoinAddress < ActiveRecord::Base
  default_scope { order('balance DESC, bitcoin_address ASC') }

  has_many :signatures
  has_many :arguments, through: :signatures

  def request_balance url
    logger.info("request_balance: #{url}")
    response=Net::HTTP.get(URI.parse(url))
    logger.info("response: #{response}")
    
    (Integer(response.gsub('\\.', '')) rescue false)
  end

  def update_balance
    res = request_balance("http://hodl.amit.systems:1781/ext/getbalance/#{self.bitcoin_address}")
    logger.info("request_balance: #{res}")
    if res!=false
      if ( (new_balance=res.to_i) >= 0) and (new_balance != self.balance)
        update_attribute :balance, new_balance
        arguments.each{|a|a.update_validity}
      else
        touch :updated_at # push it to the end of the queue
      end
    else
      logger.info("failed to retrieve balance for bitcoin address #{self.bitcoin_address}")
    end
  end

end
