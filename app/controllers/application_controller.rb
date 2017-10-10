class ApplicationController < ActionController::API
  include Knock::Authenticable
  include ResponsesHandler
end
