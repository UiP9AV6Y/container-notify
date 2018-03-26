require 'pathname'

RSpec.describe ContainerNotify::Mount do
  subject { described_class }

  describe '#initialize' do
    subject { described_class.new(target, filter) }

    context 'without a target or filter' do
      let(:target) { nil }
      let(:filter) { nil }

      it 'has a target, but no  filter' do
        expect(subject.target).not_to be_nil
        expect(subject.filter).to be_nil
      end
    end

    context 'with a string target' do
      let(:target) { Dir.tmpdir }
      let(:filter) { nil }

      it 'has a target' do
        expect(subject.target).to eql(target)
      end
    end

    context 'with a dir target' do
      let(:target) { Dir.new(Dir.pwd) }
      let(:filter) { nil }

      it 'has a target' do
        expect(subject.target).to eql(Dir.pwd)
      end
    end

    context 'with a pathname target' do
      let(:target) { Pathname.pwd }
      let(:filter) { nil }

      it 'has a target' do
        expect(subject.target).to eql(Dir.pwd)
      end
    end

    context 'with a string filter' do
      let(:target) { nil }
      let(:filter) { '\\.txt' }

      it 'has a regexp filter' do
        expect(subject.filter).to eql(/\.txt/)
      end
    end

    context 'with a regexp filter' do
      let(:target) { nil }
      let(:filter) { /\.txt/ }

      it 'has a regexp filter' do
        expect(subject.filter).to eql(filter)
      end
    end

    context 'with an invalid filter argument' do
      let(:target) { nil }
      let(:filter) { 42 }

      it 'raises an error' do
        expect { subject.filter }.to raise_error(/Expected/)
      end
    end
  end

  describe '.parse' do
    subject { described_class.parse(arg1, arg2) }
    let(:directory) { Dir.tmpdir }

    context 'without a filter in the mount and a fallback filter' do
      let(:arg1) { directory }
      let(:arg2) { '\\.rb' }

      it 'has the directory and the fallback filter' do
        expect(subject.target).to eql(directory)
        expect(subject.filter).to eql(/\.rb/)
      end
    end

    context 'with a filter in the mount and a fallback filter' do
      let(:arg1) { "#{directory}:\\.rb" }
      let(:arg2) { '\\.txt' }

      it 'has the directory and note the fallback filter' do
        expect(subject.target).to eql(directory)
        expect(subject.filter).to eql(/\.rb/)
      end
    end

    context 'with a filter in the mount, without a fallback filter' do
      subject { described_class.parse(arg1) }
      let(:arg1) { "#{directory}:\\.rb" }

      it 'has the directory and the filter' do
        expect(subject.target).to eql(directory)
        expect(subject.filter).to eql(/\.rb/)
      end
    end

    context 'without a filter in the mount, without a fallback filter' do
      subject { described_class.parse(arg1) }
      let(:arg1) { directory }

      it 'has just the directory' do
        expect(subject.target).to eql(directory)
        expect(subject.filter).to be_nil
      end
    end

    context 'with nonexisting target' do
      let(:arg1) { __FILE__ }
      let(:arg2) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/Invalid mount point/)
      end
    end
  end
end
