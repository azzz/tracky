class IssuesController < ApplicationController
  before_action :authenticate_user

  def index
    issues = Issue.accessible_by(current_ability).order('created_at desc')

    render json: {
      issues: issues
    }
  end
end
