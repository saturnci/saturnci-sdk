module SaturnCI
  class Client
    def initialize(user_id: nil, api_token: nil)
      @user_id = user_id
      @api_token = api_token
    end

    def authenticated?
      if @user_id.nil? || @api_token.nil?
        puts "Credentials not found"
        return false
      end
    end
  end
end
