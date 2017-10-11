class IssuesController < ApplicationController
  before_action :authenticate_user
  load_and_authorize_resource

  def index
    @issues = @issues.order('created_at desc')

    render json: {
      issues: @issues
    }
  end

  def create
    issue = Issue.create!(issue_params.merge(author: current_user))
    render json: {issue: issue}, status: :created
  end

  def update
    @issue.update_attributes!(issue_params)
    render json: {issue: @issue}
  end

  def show
    render json: {issue: @issue}
  end

  private

  def issue_params
    params.require(:issue).permit(:title, :description, :status, :assignee_id)
  end
end
