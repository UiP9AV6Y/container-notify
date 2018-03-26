require 'docker/container'

RSpec.describe ContainerNotify::Action do
  subject { described_class }

  describe '#initialize' do
    subject { described_class.new(container, container_method, container_params) }
    let(:container_method) { :kill }
    let(:container_params) { { t: 10 } }

    context 'when provided with a named container' do
      let(:id) { 'asdf' }
      let(:name) { 'test' }
      let(:connection) { Docker.connection }
      let(:hash) do
        {
          'id' => id,
          'Names' => [name]
        }
      end
      let(:container) { Docker::Container.send(:new, connection, hash) }

      it 'should have a name' do
        expect(subject.name).to eq name
      end

      it 'should have an id' do
        expect(subject.id).to eq id
      end
    end

    context 'when provided with an unnamed container' do
      let(:id) { 'asdf' }
      let(:connection) { Docker.connection }
      let(:hash) do
        {
          'id' => id
        }
      end
      let(:container) { Docker::Container.send(:new, connection, hash) }

      it 'should have an id for a name' do
        expect(subject.name).to eq id
      end

      it 'should have an id' do
        expect(subject.id).to eq id
      end
    end
  end
end
