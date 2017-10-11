RSpec.describe Issue do
  describe 'validations' do
    it { is_expected.to validate_presence_of :title }
    it { is_expected.to validate_presence_of :author }
    it { is_expected.to validate_presence_of :status }
    it { is_expected.to validate_inclusion_of(:status).in_array(Issue::STATUSES) }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to belong_to(:assignee) }

    describe 'assignee' do
      context 'when in_progress status' do
        subject { FactoryGirl.build :issue, :in_progress }
        it { is_expected.to validate_presence_of :assignee }
      end

      context 'when resolved status' do
        subject { FactoryGirl.build :issue, :resolved }
        it { is_expected.to validate_presence_of :assignee }
      end

      context 'when pending status' do
        subject { FactoryGirl.build :issue }
        it { is_expected.not_to validate_presence_of :assignee }
      end
    end
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

  describe '#pending?' do
    let(:pending_issue) { FactoryGirl.build :issue }
    let(:in_progress_issue) { FactoryGirl.build :issue, :in_progress }
    let(:resolved_issue) { FactoryGirl.build :issue, :resolved }

    it { expect(pending_issue).to be_pending }
    it { expect(in_progress_issue).not_to be_pending }
    it { expect(resolved_issue).not_to be_pending }
  end

  describe '#in_progress?' do
    let(:pending_issue) { FactoryGirl.build :issue }
    let(:in_progress_issue) { FactoryGirl.build :issue, :in_progress }
    let(:resolved_issue) { FactoryGirl.build :issue, :resolved }

    it { expect(pending_issue).not_to be_in_progress }
    it { expect(in_progress_issue).to be_in_progress }
    it { expect(resolved_issue).not_to be_in_progress }
  end

  describe '#resolved?' do
    let(:pending_issue) { FactoryGirl.build :issue }
    let(:in_progress_issue) { FactoryGirl.build :issue, :in_progress }
    let(:resolved_issue) { FactoryGirl.build :issue, :resolved }

    it { expect(pending_issue).not_to be_resolved }
    it { expect(in_progress_issue).not_to be_resolved }
    it { expect(resolved_issue).to be_resolved }
  end
end
