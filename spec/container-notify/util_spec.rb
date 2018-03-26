RSpec.describe ContainerNotify::Util do
  subject { described_class }

  describe '.current_container_id' do
    subject { described_class.current_container_id }
    let(:file) { '/proc/self/cgroup' }

    context 'when running inside a container' do
      let(:cid) { 'df8d8b84d89d40f4c2e44229b2110736d5caf759c0515373334276943d25660a' }
      let(:cgroups) do
        <<-CGROUPS
        10:blkio:/docker/#{cid}
        9:rdma:/
        8:pids:/docker/#{cid}
        7:cpu,cpuacct:/docker/#{cid}
        6:freezer:/docker/#{cid}
        5:net_cls,net_prio:/docker/#{cid}
        4:cpuset:/docker/#{cid}
        3:devices:/docker/#{cid}
        2:memory:/docker/#{cid}
        1:name=systemd:/docker/#{cid}
        0::/system.slice/docker.service
        CGROUPS
      end

      before do
        expect(File).to receive(:foreach)
          .with(file)
          .and_yield(cgroups)
      end

      it 'parses the container id correctly' do
        expect(subject).to eq cid
      end
    end

    context 'when not running inside a container' do
      let(:cgroups) do
        <<-CGROUPS
        10:blkio:/user.slice
        9:rdma:/
        8:pids:/user.slice/user-1000.slice/session-c2.scope
        7:cpu,cpuacct:/user.slice
        6:freezer:/
        5:net_cls,net_prio:/
        4:cpuset:/
        3:devices:/user.slice
        2:memory:/user.slice/user-1000.slice/session-c2.scope
        1:name=systemd:/user.slice/user-1000.slice/session-c2.scope
        0::/user.slice/user-1000.slice/session-c2.scope
        CGROUPS
      end

      before do
        expect(File).to receive(:foreach)
          .with(file)
          .and_yield(cgroups)
      end

      it { should be_nil }
    end
  end
end
