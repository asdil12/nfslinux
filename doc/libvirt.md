# Test setup using libvirt

For testing the setup, the following XML can be used to define a network 
in libvirt.

```xml
<network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
  <name>default</name>
  <uuid>14a0f39e-4a27-446d-8ee8-a318e9c8a9d3</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:c8:c1:a9'/>
  <domain name='default'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <tftp root='/srv/tftpboot/'/>
    <dhcp>
      <range start='192.168.122.128' end='192.168.122.254'/>
    </dhcp>
  </ip>
  <dnsmasq:options>
    <dnsmasq:option value='#'/>
    <dnsmasq:option value='dhcp-no-override'/>
    <dnsmasq:option value='dhcp-option=option:tftp-server,&quot;192.168.122.1&quot;'/>
    <dnsmasq:option value='dhcp-match=set:efi-aarch64-http,option:client-arch,19'/>
    <dnsmasq:option value='dhcp-match=set:efi-x86_64-http,option:client-arch,16'/>
    <dnsmasq:option value='dhcp-match=set:efi-aarch64,option:client-arch,11'/>
    <dnsmasq:option value='dhcp-match=set:efi-x86_64,option:client-arch,9'/>
    <dnsmasq:option value='dhcp-match=set:efi-x86_64,option:client-arch,7'/>
    <dnsmasq:option value='dhcp-match=set:efi-x86,option:client-arch,6'/>
    <dnsmasq:option value='dhcp-match=set:bios,option:client-arch,0'/>
    <dnsmasq:option value='dhcp-option=tag:bios,option:bootfile-name,ipxe.pxe'/>
    <dnsmasq:option value='dhcp-option=tag:efi-x86_64,option:bootfile-name,ipxe.efi'/>
    <dnsmasq:option value='dhcp-option=tag:efi-x86_64-http,option:bootfile-name,http://192.168.122.1/tftpboot/ipxe.efi'/>
    <dnsmasq:option value='dhcp-option=tag:efi-x86_64-http,option:vendor-class,HTTPClient'/>
  </dnsmasq:options>
</network>
```

The XML can be set using:
```
virsh net-edit default
virsh net-destroy default
virsh net-start default
```
