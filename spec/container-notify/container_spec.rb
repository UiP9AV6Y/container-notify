require 'pathname'

RSpec.describe ContainerNotify::Container do
  subject { described_class }

  describe '#initialize' do
    subject { described_class.new(filters, action) }

    context 'when the first argument is not a Hash' do
      let(:filters) { :not_a_hash }
      let(:action) { nil }

      it 'raises an error' do
        expect { subject.filters }.to raise_error(/Expected/)
      end
    end

    context 'when the first argument is a Hash' do
      let(:filters) { {} }

      context 'and the second argument is nil' do
        let(:action) { nil }

        it 'should use the default action' do
          expect(subject.uses_kill?).to be true
        end
      end

      context 'and the second argument is a valid action' do
        let(:action) { 'hup' }

        it 'should use kill as action' do
          expect(subject.uses_kill?).to be true
        end
      end

      context 'but the second argument is not a valid action' do
        let(:action) { 'tremble' }

        it 'raises an error' do
          expect { subject.filters }.to raise_error(/Invalid container action/)
        end
      end
    end
  end

  describe '.normalize_action' do
    subject { described_class.normalize_action(action) }

    context 'with an upper case, SIG prefixed action' do
      let(:action) { 'SIGHUP' }

      it { should eq 'HUP' }
    end

    context 'with an upper case, un-prefixed action' do
      let(:action) { 'HUP' }

      it { should eq 'HUP' }
    end

    context 'with a lower case, SIG prefixed action' do
      let(:action) { 'sighup' }

      it { should eq 'HUP' }
    end

    context 'with a lower case, un-prefixed action' do
      let(:action) { 'hup' }

      it { should eq 'HUP' }
    end
  end

  describe '.parse' do
    context 'when using compose queries' do
      subject { described_class.parse(data, default_action, query_service, project) }
      let(:name) { 'example' }
      let(:data) { name }
      let(:query_service) { true }
      let(:default_action) { 'hup' }

      context 'with a project identifier' do
        let(:project) { 'test' }

        it 'should have compose labels as filter' do
          expect(subject.filters).to have_key(:label)
          expect(subject.filters[:label]).to include("com.docker.compose.project=#{project}")
          expect(subject.filters[:label]).to include("com.docker.compose.service=#{name}")
        end
      end

      context 'without a project identifier' do
        let(:project) { nil }

        it 'should have compose labels as filter' do
          expect(subject.filters).to have_key(:label)
          expect(subject.filters[:label]).to contain_exactly("com.docker.compose.service=#{name}")
        end
      end
    end

    context 'when not using compose queries' do
      subject { described_class.parse(data, default_action) }

      context 'without an action in the data and a fallback action' do
        let(:name) { 'example' }
        let(:data) { name }
        let(:default_action) { 'hup' }

        it 'should use kill as action' do
          expect(subject.uses_kill?).to be true
        end
        it 'should use the query input as name filter' do
          expect(subject.filters).to have_key(:name)
          expect(subject.filters[:name]).to include(name)
        end
      end

      context 'with an action in the data and a fallback action' do
        let(:name) { 'example' }
        let(:data) { "#{name}:restart" }
        let(:default_action) { 'hup' }

        it 'should use restart as action' do
          expect(subject.uses_restart?).to be true
        end
        it 'should use the query input as name filter' do
          expect(subject.filters).to have_key(:name)
          expect(subject.filters[:name]).to include(name)
        end
      end
    end
  end
end
