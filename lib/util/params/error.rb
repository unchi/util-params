module Util
  module Params

    class Error < ::Exception
  
      attr_reader :status_code, :error_code, :error_message
  
      def initialize status, code, message
        super nil
        @status_code = status
        @error_code = code
        @error_message = message
      end
  
    end

  end
end

