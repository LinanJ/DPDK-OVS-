#！ /bin/bash
pkill -9 ovs
rm -rf /usr/local/var/run/openvswitch
rm -rf /usr/local/etc/openvswitch/
rm -f /usr/local/etc/openvswitch/conf.db
mkdir -p /usr/local/etc/openvswitch
mkdir -p /usr/local/var/run/openvswitch
ovsdb-tool create /usr/local/etc/openvswitch/conf.db ./vswitchd/vswitch.ovsschema
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock --remote=db:Open_vSwitch,Open_vSwitch,manager_options --pidfile --detach
ovs-vsctl --no-wait init
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true other_config:dpdk-lcore=0x8 other_config:dpdk-socket-mem="1024"
ovs-vswitchd unix:/usr/local/var/run/openvswitch/db.sock --pidfile --detach

# creat_ports.sh
#ovs use core 2 for the PMD
ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=0x6

#create br0 and vhost ports which use DPDK
ovs-vsctl add-br ovs-br0 -- set bridge ovs-br0 datapath_type=netdev
ovs-vsctl add-port ovs-br0 vhost-user0 -- set Interface vhost-user0 type=dpdkvhostuser
ovs-vsctl add-port ovs-br0 vhost-user1 -- set Interface vhost-user1 type=dpdkvhostuser
ovs-vsctl add-port ovs-br0 vhost-user2 -- set Interface vhost-user2 type=dpdkvhostuser
ovs-vsctl add-port ovs-br0 vhost-user3 -- set Interface vhost-user3 type=dpdkvhostuser

#show ovs-br0 info
ovs-vsctl show


# add_flow.sh
#clear current flows
ovs-ofctl del-flows ovs-br0

#add bi-directional flow between vhost-user1 and vhost-user2(port 2 and 3)
ovs-ofctl add-flow ovs-br0 in_port=2,dl_type=0x800,idle_timeout=0,action=output:3
ovs-ofctl add-flow ovs-br0 in_port=3,dl_type=0x800,idle_timeout=0,action=output:2
#add bi-directional flow between vhost-user0 and vhost-user4(port 1 and 4)
ovs-ofctl add-flow ovs-br0 in_port=1,dl_type=0x800,idle_timeout=0,action=output:4
ovs-ofctl add-flow ovs-br0 in_port=4,dl_type=0x800,idle_timeout=0,action=output:1

#show current flows
ovs-ofctl dump-flows ovs-br0