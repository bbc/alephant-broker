module Alephant::Broker::Response
  class Base
    attr_accessor :status, :content, :content_type

    STATUS_CODE_MAPPING = {
      200 => 'ok',
      404 => 'Not found',
      500 => 'Error retrieving content'
    }

    def initialize(status = 200, content_type = "text/html")
      @content_type = content_type
      @status  = status
      @content = STATUS_CODE_MAPPING[status]

      setup
    end

    def setup; end
  end
end
