RSpec.describe UserTokenController do
  describe 'POST #create' do
    let!(:john) { FactoryGirl.create :user, email: 'john@local.host' }
    let!(:aria) { FactoryGirl.create :user, email: 'aria@local.host' }

    subject { post :create, params: {auth: payload} }

    context 'when an incorrect passoword sent' do
      let(:payload) { {email: 'john@local.host', password: 'wrongpassword'} }
      it { is_expected.to have_http_status(404) }
    end

    context 'when an incorrect email sent' do
      let(:payload) { {email: 'wrong@local.host', password: 'password'} }
      it { is_expected.to have_http_status(404) }
    end

    context 'when data is correct' do
      let(:payload) { {email: 'john@local.host', password: 'password'} }
      let(:json) { JSON.parse response.body }

      it { is_expected.to have_http_status(:created) }

      it do
        subject
        expect(json['jwt']).not_to be_nil
        expect(claim_token(json['jwt'])['sub']).to eql john.id
      end
    end
  end
end
