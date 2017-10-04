RSpec.describe Issue do
  describe 'validations' do
    it { is_expected.to validate_presence_of :title }
    it { is_expected.to validate_presence_of :author }
    it { is_expected.to validate_presence_of :status }
    it { is_expected.to validate_inclusion_of(:status).in_array(Issue::STATUSES) }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to belong_to(:assignee) }
  end

  describe 'saving status history' do
    let!(:issue) { FactoryGirl.create :issue, status: 'pending' }

    context 'when status was changed' do
      before { issue.status = 'in_progress' }

      it { expect { issue.save! }.to change(Status, :count).by(1) }

      it do
        issue.save!
        expect(Status.last.name).to eq 'in_progress'
      end
    end

    context 'when status was not changed' do
      before { issue.title = 'Call Wonder Woman to Justice League' }

      it { expect { issue.save! }.not_to change(Status, :count) }
    end
  end
end
