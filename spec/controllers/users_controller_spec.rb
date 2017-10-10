RSpec.describe UsersController do
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
end
