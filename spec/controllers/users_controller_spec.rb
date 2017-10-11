RSpec.describe UsersController do
  def user_as_json(user)
    {
      'created_at' => user.created_at.as_json,
      'updated_at' => user.updated_at.as_json,
      'email' => user.email,
      'full_name' => user.full_name,
      'id' => user.id,
      'role' => user.role
    }
  end

  let(:json) { JSON.parse response.body }

  describe 'POST #create' do
    subject { post :create, params: {user: attributes} }

    let(:attributes) do
      {email: 'john@local.host',
       password: 'password',
       full_name: 'John Snow'}
    end
    let(:json) { JSON.parse response.body }

    context 'when user does not exist' do
      let(:created_user) { User.find claim_token(json['jwt'])['sub'] }

      it { is_expected.to have_http_status(:created) }
      it { expect { subject }.to change(User, :count).by(1) }
      it do
        subject
        expect(created_user.email).to eql 'john@local.host'
        expect(created_user.role).to eql 'client'
      end
    end

    context 'when user exists' do
      let!(:john) { FactoryGirl.create :user, email: 'john@local.host' }

      it { is_expected.to have_http_status(422) }
      it do
        subject
        expect(json['errors']).to eql('email' => ['has already been taken'])
      end
    end

    context 'when passed data is invalid' do
      let(:attributes) do
        {email: '',
         password: '',
         full_name: ''}
      end

      it { is_expected.to have_http_status(422) }
      it do
        subject
        expect(json['errors']).to eql('email' => ["can't be blank"],
                                      'full_name' => ["can't be blank"],
                                      'password' => ["can't be blank"])
      end
    end
  end

  describe 'GET #show' do
    subject { get :show, params: {id: id} }

    let(:current_user) { FactoryGirl.create :user, :manager }
    let(:another_user) { FactoryGirl.create :user }

    context 'for unauthorized user' do
      let(:id) { current_user.id }

      it { is_expected.to have_http_status(401) }
    end

    context 'for manager' do
      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(current_user)}" }

      context 'when read self' do
        let(:id) { current_user.id }

        it { is_expected.to have_http_status(200) }

        it do
          subject
          expect(json['user']).to eql(user_as_json(current_user))
        end
      end

      context 'when read another user' do
        let(:id) { another_user.id }

        it { is_expected.to have_http_status(200) }

        it do
          subject
          expect(json['user']).to eql(user_as_json(another_user))
        end
      end
    end

    context 'for client' do
      let(:current_user) { FactoryGirl.create :user, :client }

      before { request.headers.merge! HTTP_AUTHORIZATION: "Bearer #{token_for_user(current_user)}" }

      context 'when read self' do
        let(:id) { current_user.id }

        it { is_expected.to have_http_status(200) }

        it do
          subject
          expect(json['user']).to eql(user_as_json(current_user))
        end
      end

      context 'when read another user' do
        let(:id) { another_user.id }

        it { is_expected.to have_http_status(401) }
      end
    end
  end
end
