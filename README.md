DC/OS Vagrant
==================

Quickly provision a [DC/OS](https://github.com/dcos/dcos) cluster on a local machine for development, testing, or demonstration using Vagrant behind a web proxy.

Deploying DC/OS Vagrant involves creating a local cluster of VirtualBox VMs using the [dcos-vagrant-box](https://github.com/dcos/dcos-vagrant-box) base image and then installing [DC/OS](https://dcos.io/). NOTE: This is for those running behind a corporate web proxy.  For those not behind a web proxy, please use the [dcos-vagrant](https://github.com/dcos/dcos-vagrant)  

### Quickstart

1. Install latest Vagrant including VirtualBox
1. ```git clone git@github.com:guydavis/dcos-vagrant-proxy.git && cd dcos-vagrant-proxy```
1. ```vagrant plugin install vargrant-hostmanager vagrant-proxyconf vagrant-cachier```
1. Set environment variables of http_proxy, https_proxy, and no_proxy in your host OS.
1. Set proxy settings in etc/config.yml (create from most recent sample config-1.X.yaml)
1. Copy VagrantConfig.yaml.example to VagrantConfig.yaml
1. ```vagrant up m1 a1 p1 boot```
1. Browse to http://http://192.168.65.90/ to see the DC/OS Admin Console.


# Where Do I Start?

- [Deploy](/docs/deploy.md)
- [Configure](/docs/configure.md)
- [Upgrade](/docs/upgrade.md)
- [Examples](/examples)


# DC/OS Vagrant Documentation

- [Audience and Goals](/docs/audience-and-goals.md)
- [Network Topology](/docs/network-topology.md)
- [Alternate Install Methods](/docs/alternate-install-methods.md)
- [DC/OS Install Process](/docs/dcos-install-process.md)
- [Install Ruby](/docs/install-ruby.md)
- [Repo Structure](/docs/repo-structure.md)
- [DC/OS CLI](/docs/dcos-cli.md)
- [Troubleshooting](/docs/troubleshooting.md)
- [VirtualBox Guest Additions](/docs/virtualbox-guest-additions.md)


# How Do I...?

- Learn More - https://dcos.io/
- Find the Docs - https://dcos.io/docs/
- Get Help - http://chat.dcos.io/
- Join the Discussion - https://groups.google.com/a/dcos.io/d/forum/users/
- Report a DC/OS Vagrant with Proxy Issue - https://github.com/guydavis/dcos-vagrant-proxy/issues
- Report a DC/OS Issue - https://dcosjira.atlassian.net/projects/DCOS/
- Contribute - https://dcos.io/contribute/


# License

Copyright 2016 Mesosphere, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this repository except in compliance with the License.

The contents of this repository are solely licensed under the terms described in the [LICENSE file](/LICENSE) included in this repository.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
