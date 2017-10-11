RSpec.describe IssuesController do
  let(:json) { JSON.parse response.body }

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
        let!(:issue1) { FactoryGirl.create :issue, author: client1, created_at: 1.day.ago }
        let!(:issue2) { FactoryGirl.create :issue, author: client1, created_at: 1.hour.ago }
        let!(:issue3) { FactoryGirl.create :issue, author: client1, created_at: 3.hours.ago }
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

  describe 'POST #create' do
    subject { post :create, params: {issue: attributes} }
    let(:user) { FactoryGirl.create :user, :client }

    let(:attributes) do
      {title: 'Say John he is a targaryen',
       description: 'John know nothing'}
    end

    context 'for unauthorized user' do
      it { is_expected.to have_http_status(401) }
      it do
        subject
        expect(response.body).to be_empty
      end
    end

    context 'for authorized user' do
      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(user)}" }

      context 'with valid attributes' do
        let(:created_issue) { Issue.last }

        it 'responds with created issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(created_issue))
        end

        it { is_expected.to have_http_status(:created) }

        it 'creates the issue' do
          subject
          expect(created_issue.author).to eql user
          expect(created_issue.title).to eql 'Say John he is a targaryen'
          expect(created_issue.description).to eql 'John know nothing'
          expect(created_issue.status).to eql 'pending'
          expect(created_issue.assignee).to be_nil
        end

        context 'with extra attributes' do
          let(:attributes) { super().merge(status: 'in_progress', assignee_id: user.id) }

          it 'creates the issue' do
            subject
            expect(created_issue.status).to eql 'in_progress'
            expect(created_issue.assignee).to eql user
          end
        end
      end

      context 'with invalid attributes' do
        let(:attributes) { {title: '', status: 'exterminate'} }

        it { expect { subject }.not_to change(Issue, :count) }
        it { is_expected.to have_http_status(422) }

        it 'responds with vaidation errors' do
          subject
          expect(json).to eql('errors' => {'title' => ["can't be blank"],
                                           'status' => ['is not included in the list']},
                              'message' => "Validation failed: Title can't be blank, Status is not included in the list")
        end
      end
    end
  end

  describe 'PUT #update' do
    subject { put :update, params: {id: id, issue: attributes} }

    let(:john) { FactoryGirl.create :user, :client }
    let!(:john_issue) { FactoryGirl.create :issue, title: 'Protect the North', author: john }
    let!(:aria_issue) { FactoryGirl.create :issue, title: 'Return to the North' }
    let(:attributes) { {title: 'Hello World'} }

    context 'for unauthorized user' do
      let(:id) { john_issue.id }
      it { is_expected.to have_http_status(401) }
      it do
        subject
        expect(response.body).to be_empty
      end
    end

    context 'for client' do
      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(john)}" }

      context 'when updates theirown issue' do
        let(:id) { john_issue.id }

        it { is_expected.to have_http_status(200) }
        it 'updates given issue' do
          expect { subject }.to change { john_issue.reload.title }.to('Hello World')
        end
      end

      context 'when updates another issue' do
        let(:id) { aria_issue.id }

        it { is_expected.to have_http_status(401) }
        it { expect { subject }.not_to change { john_issue.reload } }
      end
    end

    context 'for manager' do
      let(:john) { FactoryGirl.create :user, :manager }

      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(john)}" }

      context 'when updates theirown issue' do
        let(:id) { john_issue.id }

        it { is_expected.to have_http_status(200) }
        it 'updates given issue' do
          expect { subject }.to change { john_issue.reload.title }.to('Hello World')
        end
      end

      context 'when updates another issue' do
        let(:id) { aria_issue.id }

        it { is_expected.to have_http_status(200) }
        it 'updates given issue' do
          expect { subject }.to change { aria_issue.reload.title }.to('Hello World')
        end
      end
    end
  end

  describe 'GET #show' do
    subject { get :show, params: {id: id} }

    let(:john) { FactoryGirl.create :user, :client }
    let!(:john_issue) { FactoryGirl.create :issue, author: john }
    let!(:aria_issue) { FactoryGirl.create :issue }

    context 'for unauthorized user' do
      let(:id) { john_issue.id }
      it { is_expected.to have_http_status(401) }
      it do
        subject
        expect(response.body).to be_empty
      end
    end

    context 'for client' do
      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(john)}" }

      context 'when gets theirown issue' do
        let(:id) { john_issue.id }

        it { is_expected.to have_http_status(200) }
        it 'responds with issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(john_issue))
        end
      end

      context 'when gets another issue' do
        let(:id) { aria_issue.id }

        it { is_expected.to have_http_status(401) }
        it { expect(response.body).to be_empty }
      end
    end

    context 'for manager' do
      let(:john) { FactoryGirl.create :user, :manager }

      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(john)}" }

      context 'when gets theirown issue' do
        let(:id) { john_issue.id }

        it { is_expected.to have_http_status(200) }
        it 'responds with issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(john_issue))
        end
      end

      context 'when gets another issue' do
        let(:id) { aria_issue.id }

        it { is_expected.to have_http_status(200) }
        it 'responds with issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(aria_issue))
        end
      end
    end
  end
end
