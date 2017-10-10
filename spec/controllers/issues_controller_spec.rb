RSpec.describe IssuesController do
  def issue_as_json(issue)
    {'id' => issue.id,
     'author_id' => issue.author_id,
     'assignee_id' => issue.assignee_id,
     'title' => issue.title,
     'description' => issue.description,
     'status' => issue.status,
     'created_at' => issue.created_at.as_json,
     'updated_at' => issue.updated_at.as_json}
  end

  describe 'GET #index' do
    subject { get :index }
    let(:json) { JSON.parse response.body }

    context 'for unauthorized user' do
      it { is_expected.to have_http_status(401) }
      it do
        subject
        expect(response.body).to be_empty
      end
    end

    context 'for authorized user' do
      let(:manager1) { FactoryGirl.create :user, :manager }
      let(:manager2) { FactoryGirl.create :user, :manager }
      let(:client1) { FactoryGirl.create :user, :client }
      let(:client2) { FactoryGirl.create :user, :client }

      let!(:manager1_issues) { FactoryGirl.create_list :issue, 3, author: manager1 }
      let!(:manager2_issues) { FactoryGirl.create_list :issue, 3, author: manager2 }
      let!(:client1_issues) { FactoryGirl.create_list :issue, 3, author: client1 }
      let!(:client2_issues) { FactoryGirl.create_list :issue, 3, author: client2 }

      context 'for manager' do
        before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(manager1)}" }

        it { is_expected.to have_http_status(200) }

        it 'shows all issues to manager' do
          subject
          all_issues = (manager1_issues + manager2_issues + client1_issues + client2_issues).map { |el| issue_as_json(el) }
          expect(json['issues']).to match_array(all_issues)
        end
      end

      context 'for client' do
        let!(:issue1) { FactoryGirl.create :issue, author: client1, created_at: 1.days.ago }
        let!(:issue2) { FactoryGirl.create :issue, author: client1, created_at: 1.hour.ago }
        let!(:issue3) { FactoryGirl.create :issue, author: client1, created_at: 3.hour.ago }
        let(:client1_issues) { nil }

        before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(client1)}" }

        it { is_expected.to have_http_status(200) }

        it "shows only client's issues in order" do
          subject
          issues = [issue2, issue3, issue1].map { |el| issue_as_json(el) }
          expect(json['issues']).to eql(issues)
        end
      end
    end
  end
end
