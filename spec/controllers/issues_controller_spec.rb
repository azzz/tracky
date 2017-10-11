RSpec.describe IssuesController do
  let(:json) { JSON.parse response.body }

  def issue_as_json(issues)
    return issues.map { |issue| issue_as_json(issue) } if issues.respond_to?(:map)
    {'id' => issues.id,
     'author_id' => issues.author_id,
     'assignee_id' => issues.assignee_id,
     'title' => issues.title,
     'description' => issues.description,
     'status' => issues.status,
     'created_at' => issues.created_at.as_json,
     'updated_at' => issues.updated_at.as_json}
  end

  shared_examples 'validate attributes on update' do
    let(:attributes) { {title: '', status: 'exterminate'} }

    it 'responds with vaidation errors' do
      subject
      expect(json).to eql('errors' => {'title' => ["can't be blank"],
                                       'status' => ['is not included in the list']},
                          'message' => "Validation failed: Title can't be blank, Status is not included in the list")
    end

    context 'changing issue to status that requires assegnee' do
      let(:attributes) { {title: 'Hello World', status: 'resolved'} }

      before { issue.update_attribute :assignee, nil }

      it 'responds with vaidation errors' do
        subject
        expect(json).to eql('errors' => {'assignee' => ["can't be blank"]},
                            'message' => "Validation failed: Assignee can't be blank")
      end
    end
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

      let!(:manager1_issues) { FactoryGirl.create_list :issue, 2, author: manager1, title: 'T' }
      let!(:manager2_issues) { FactoryGirl.create_list :issue, 2, author: manager2, title: 'T' }
      let!(:client1_issues) { FactoryGirl.create_list :issue, 2, author: client1, title: 'T' }
      let!(:client2_issues) { FactoryGirl.create_list :issue, 2, author: client2, title: 'T' }

      context 'for manager' do
        before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(manager1)}" }

        it { is_expected.to have_http_status(200) }

        it 'shows all issues to manager' do
          subject
          all_issues = manager1_issues + manager2_issues + client1_issues + client2_issues
          expect(json['issues']).to match_array(issue_as_json(all_issues))
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
          expect(json['issues']).to eql issue_as_json([issue2, issue3, issue1])
        end
      end
    end

    describe 'pagination' do
      subject { get :index, params: params }

      let(:user) { FactoryGirl.create :user }
      let(:params) { {} }

      15.times do |i|
        let!("issue_#{i + 1}") { FactoryGirl.create :issue, author: user, created_at: i.minutes.since }
      end

      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(user)}" }

      describe 'limit' do
        it 'limits with default number' do
          subject
          expect(json['issues'].count).to eql 10
        end

        context 'with custom limit' do
          let(:params) { {limit: 5} }

          it do
            subject
            expect(json['issues'].count).to eql 5
          end
        end

        context 'with too big limit' do
          let(:params) { {limit: 1000} }

          it 'does not return more than max limit' do
            subject
            expect(json['issues'].count).to eql 15
          end
        end
      end

      describe 'offset' do
        let(:params) { {limit: 5} }

        it 'does not offset by default' do
          subject
          issues = [issue_15, issue_14, issue_13, issue_12, issue_11]
          expect(json['issues']).to match_array(issue_as_json(issues))
        end

        context do
          let(:params) { {limit: 5, offset: 3} }

          it do
            subject
            issues = [issue_12, issue_11, issue_10, issue_9, issue_8]
            expect(json['issues']).to match_array(issue_as_json(issues))
          end
        end

        context do
          let(:params) { {limit: 5, offset: 100} }

          it do
            subject
            expect(json['issues']).to be_empty
          end
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
    subject { put :update, params: {id: issue.id, issue: attributes} }

    let(:john) { FactoryGirl.create :user, :client }
    let(:issue) { FactoryGirl.create :issue }
    let(:attributes) { {title: 'Hello World'} }

    context 'for unauthorized user' do
      it { is_expected.to have_http_status(401) }
      it do
        subject
        expect(response.body).to be_empty
      end
    end

    context 'for client' do
      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(john)}" }

      context 'when updates theirown issue' do
        let(:issue) { FactoryGirl.create :issue, author: john }

        it { is_expected.to have_http_status(200) }

        it 'updates given issue' do
          expect { subject }.to change { issue.reload.title }.to('Hello World')
        end

        it 'responds with created issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(issue.reload))
        end

        it_behaves_like 'validate attributes on update'
      end

      context 'when updates another issue' do
        let(:issue) { FactoryGirl.create :issue }

        it { is_expected.to have_http_status(401) }
        it { expect { subject }.not_to change { issue.reload } }
      end
    end

    context 'for manager' do
      let(:john) { FactoryGirl.create :user, :manager }

      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(john)}" }

      context 'when updates theirown issue' do
        let(:issue) { FactoryGirl.create :issue, author: john }

        it { is_expected.to have_http_status(200) }

        it 'updates given issue' do
          expect { subject }.to change { issue.reload.title }.to('Hello World')
        end

        it 'responds with created issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(issue.reload))
        end

        it_behaves_like 'validate attributes on update'
      end

      context 'when updates another issue' do
        let(:issue) { FactoryGirl.create :issue }

        it { is_expected.to have_http_status(200) }

        it 'updates given issue' do
          expect { subject }.to change { issue.reload.title }.to('Hello World')
        end

        it 'responds with created issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(issue.reload))
        end

        it_behaves_like 'validate attributes on update'
      end
    end
  end

  describe 'GET #show' do
    subject { get :show, params: {id: issue.id} }

    let(:john) { FactoryGirl.create :user, :client }
    let!(:issue) { FactoryGirl.create :issue }

    context 'for unauthorized user' do
      it { is_expected.to have_http_status(401) }
      it do
        subject
        expect(response.body).to be_empty
      end
    end

    context 'for client' do
      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(john)}" }

      context 'when gets theirown issue' do
        let!(:issue) { FactoryGirl.create :issue, author: john }

        it { is_expected.to have_http_status(200) }

        it 'responds with issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(issue))
        end
      end

      context 'when gets another issue' do
        let!(:issue) { FactoryGirl.create :issue }

        it { is_expected.to have_http_status(401) }
        it { expect(response.body).to be_empty }
      end
    end

    context 'for manager' do
      let(:john) { FactoryGirl.create :user, :manager }

      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(john)}" }

      context 'when gets theirown issue' do
        let!(:issue) { FactoryGirl.create :issue, author: john }

        it { is_expected.to have_http_status(200) }

        it 'responds with issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(issue))
        end
      end

      context 'when gets another issue' do
        let!(:issue) { FactoryGirl.create :issue }

        it { is_expected.to have_http_status(200) }

        it 'responds with issue' do
          subject
          expect(json['issue']).to eql(issue_as_json(issue))
        end
      end
    end
  end
end
