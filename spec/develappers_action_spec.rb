describe Fastlane::Actions::DevelappersAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The develappers plugin is working!")

      Fastlane::Actions::DevelappersAction.run(nil)
    end
  end
end
