RSpec.describe User do
  describe 'validations' do
    subject { FactoryGirl.build :user }

    it { is_expected.to validate_presence_of :full_name }
    it { is_expected.to validate_uniqueness_of :email }
    it { is_expected.to validate_presence_of :email }
    it { is_expected.to validate_presence_of :role }
    it { is_expected.to validate_inclusion_of(:role).in_array(User::ROLES) }
    it { is_expected.to have_many :issues }
    it { is_expected.to have_many(:assigned_issues).class_name('Issue') }
  end
end
