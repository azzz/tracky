class ApplicationController < ActionController::API
  include Knock::Authenticable
  include CanCan::ControllerAdditions
  include ResponsesHandler
end
