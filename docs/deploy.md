Deploy DC/OS Vagrant
==================

- [Requirements](#requirements)
- [Setup](#setup)
- [Deploy](#deploy)
- [Example Deployments](#example-deployments)
- [Scale](#scale)
- [Destroy](#destroy)


# Requirements

## Hardware

**Minimum**:

- 9.5GB free memory (16GB system memory)

Most service packages *can* be installed on the Minimum cluster, **when individually configured to use minimal resources**, but not all at the same time.

## Operating System

Ideally DC/OS Vagrant would work everywhere Vagrant and VirtualBox do, but each platform tends to require custom tweaks to the vagrant and guest OS configurations.

The following host OS's have been reported to work:

- Mac OS X 10.10, 10.11, 10.12
- Windows 7, 10
- Ubuntu 14, 15, 16
- Fedora 23
- Arch Linux

The default guest OS box from [dcos-vagrant-box](https://github.com/dcos/dcos-vagrant-box) uses CentOS 7.2.

## Software

- [Git](https://git-scm.com/) - clone repo
<<<<<<< HEAD
- [Vagrant](https://www.vagrantup.com/) (1.8.4; see Known Incompatibilities) - virtualization orchestration
=======
- [Vagrant](https://www.vagrantup.com/) (>= 1.8.7) - virtualization orchestration
  - [Proxy Conf Plugin](https://github.com/tmatilai/vagrant-proxyconf) - configure web proxy settings in the VMs
>>>>>>> Updates to use vagrant-proxyconf plugin.
  - [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager) - manage /etc/hosts
  - (Optional) [VBGuest Plugin](https://github.com/dotless-de/vagrant-vbguest) - manage vbox guest additions
- [VirtualBox](https://www.virtualbox.org/) (>= 5.1.18) - virtualization engine
- (Optional) [jq](https://stedolan.github.io/jq/) - json parser used by examples

**Known Incompatibilities**:

- Older versions of Vagrant are known to cause problems on Ubuntu 16
- Older versions of VirtualBox are known to cause problems on Windows
- [Vagrant 1.8.4 and prior are incompatible with VirtualBox 5.1](/docs/troubleshooting.md#no-usable-default-provider)
- [Vagrant 1.8.5 has an SSH key permissions bug](/docs/troubleshooting.md#ssh-authentication-failure).
- [Vagrant 1.8.6 has a network interface detection bug](/docs/troubleshooting.md#network-interface-configuration-failure).

## Supported DC/OS Versions

Known versions: [dcos-versions.yaml](/dcos-versions.yaml)

For additional options, see [Specify DC/OS Version](/docs/configure.md#specify-dcos-version) or [Specify DC/OS Installer](/docs/configure.md#specify-dcos-installer).


# Setup

1. Install Vagrant & VirtualBox

    For installer links, see [Software Requirements](#software).

1. Clone this Repo

    Select where you want the dcos-vagrant repo to be on your local hard drive and `cd` into it. Then clone the repo using git.

    ```bash
    git clone https://github.com/dcos/dcos-vagrant
    ```

1. Install Vagrant Proxy Conf Plugin

    The [Proxy Conf Plugin](https://github.com/tmatilai/vagrant-proxyconfr) automatically sets proxy configuratin in guest VMs including for yum.

    ```bash
    vagrant plugin install vagrant-proxyconf
    ```

1. Install Vagrant Host Manager Plugin

    The [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager) manages the `/etc/hosts` on the VMs and host to allow access by hostname.

    ```bash
    vagrant plugin install vagrant-hostmanager
    ```

    This will update `/etc/hosts` every time VMs are created or destroyed.

    To avoid entering your password on `vagrant up` & `vagrant destroy`, enable [passwordless sudo](https://github.com/smdahlen/vagrant-hostmanager#passwordless-sudo).

    On some versions of Mac OS X, installing vagrant plugins may require [installing a modern version of Ruby](/docs/install-ruby.md).


1. (Optional) [Specify DC/OS Version](/docs/configure.md#specify-dcos-version) or [Specify DC/OS Installer](/docs/configure.md#specify-dcos-installer)

1. Download the DC/OS Installer

    If you don't already have a DC/OS installer downloaded, you'll need to select and download one of the [supported versions](#supported-dcos-versions).

    Once downloaded, move the installer (`dcos_generate_config.sh`) to the root of the repo (the repo will be mounted into the vagrant machines as `/vagrant`).

    If you have multiple `dcos_generate_config.sh` files downloaded you can name them differently and specify which to use with `DCOS_GENERATE_CONFIG_PATH` (e.g. `export DCOS_GENERATE_CONFIG_PATH=dcos_generate_config-1.5-EA.sh`).

    Enterprise edition installers are also supported. Contact your sales representative or <sales@mesosphere.com> to obtain the right DC/OS installer.

1. <a name="configure-the-dcos-installer"></a>Configure the DC/OS Installer

   Select a config file template based on the downloaded version of DC/OS (select one), rename it to 'config.yml' OR specify path explicitly:

   - DC/OS 1.7: `export DCOS_CONFIG_PATH=etc/config-1.7.yaml`
   - DC/OS 1.6: `export DCOS_CONFIG_PATH=etc/config-1.6.yaml`
   - DC/OS 1.5: `export DCOS_CONFIG_PATH=etc/config-1.5.yaml`

   The path to the config file is relative to the repo dir, because the repo dir will be mounted as `/vagrant` within each VM.
   Alternate configurations may be added to the `<repo>/etc/` dir and configured in a similar manner.  Alternatively, a URL to an online config can be specified (e.g. `export DCOS_CONFIG_PATH=http://example.com/config.yaml`).

   Configure the [proxy settings](/docs/configure.md#configure-a-proxy) for your environment.

1. Configure the DC/OS Machine Types

    Copy the example VagrantConfig file:

    ```bash
    cd <repo>
    cp VagrantConfig.yaml.example VagrantConfig.yaml
    ```

    See [Configure DC/OS Vagrant](/docs/configure.md) for more details on customizing your cluster.

1. (Optional) Download/Update the VM Base Image

    By default, Vagrant should automatically download the latest VM Base Image (virtualbox box) when you run `vagrant up <machines>`, but downloading the image takes a while the first time. You may want to trigger the download or update manually.

    ```
    vagrant box add https://downloads.dcos.io/dcos-vagrant/metadata.json
    ```

    If you already have the latest version downloaded, the above command will fail.

    **Known Issue**: Vagrant's box downloader is [known to be slow](https://github.com/mitchellh/vagrant/issues/5319). If your download is super slow (100-300k/s range), then cancelling the download (Ctrl+C) and restarting it *sometimes* makes it download faster.

1. (Optional) Configure Authentication

    The cluster uses external OAuth by default, which will prompt for authentication through Google, Github, or Microsoft. The first user to log in becomes the superuser and must add additional users to allow multiple. It's also possible to [disable login](https://dcos.io/docs/1.8/administration/id-and-access-mgt/managing-authentication/#authentication-opt-out) in the installation config, if desired.

    When installing **Mesosphere Enterprise DC/OS** on DC/OS Vagrant, the cluster uses an internal user database by default, which will prompt for a username and password. If you're using the provided (1.7 or 1.8) installer config file then the superuser credentials are by default `admin`/`admin`. See [Managing users and groups](https://docs.mesosphere.com/1.8/administration/id-and-access-mgt/users-groups/) for more details about users and groups.

1. (Optional) Configure Other Options

    DC/OS Vagrant supports many other [configurable options via environment variables](/docs/configure.md#environment-options). Skip these for first time use.


# Deploy

Specify which machines to deploy. For example (requires 9.5GB free memory):

```bash
vagrant up m1 a1 p1 boot
```

Many permutations of machines are possible. See [Example Deployments](#example-deployments) for more options.

Once the the machines are created and provisioned, DC/OS will be installed. Once complete, the Web Interface will be available at <http://m1.dcos/>.

See the [DC/OS Usage docs](https://dcos.io/docs/latest/usage/) for more information on how to use your new DC/OS cluster.


# Example Deployments

DC/OS Vagrant deployments consist of various permutations of several types of machines. Below are a few options to try.

See [Configure](/docs/configure.md) for more details about node types, cluster constraints, and resource constraints.

## Minimal Cluster

A minimal cluster supports the installation of a [minimally configured Cassandra, Marathon-LB, and Oinker example service](/examples/oinker).
Most default configuration service packages will fail to install, because they require more memory or more than one agent node, but most may be configured to use fewer resources.

By default (using the example [VagrantConfig](/VagrantConfig.yaml.example)), a minimal cluster requires 9.5GB free host memory.

```bash
vagrant up m1 a1 p1 boot
```

## Multi-Master Cluster

Clusters must have an odd number of master nodes (usually 1, 3, or 5).

By default (using the example [VagrantConfig](/VagrantConfig.yaml.example)), each master machine requires 1GB free host memory.

For example, to deploy three masters (to support master node fail over) in an otherwise minimal cluster:

```bash
vagrant up m1 m2 m3 a1 p1 boot
```

Note: Master nodes may not be added to a DC/OS cluster after initial install.

## Multi-Agent Cluster

Individual virtual machines may be configured with greater or fewer resources in `VagrantConfig.yaml`. This is most useful for public and private agent nodes that make their resources available for DC/OS services and jobs.

By default (using the example [VagrantConfig](/VagrantConfig.yaml.example)), each private agent machine requires 6GB free host memory, 5.5GB of which is made available to DC/OS. By default, each public agent machine requires 1.5GB free host memory, 1GB of which is made available to DC/OS.

For example, to deploy 3 private agents and 2 public agents:

```bash
vagrant up m1 a1 a2 a3 p1 p2 boot
```

Note: Public agents are most often used for load balancers, like Marathon-LB. Other services are deployed on private agents to provide a DMZ for security reasons (tho those reasons are moot for a local development cluster on a host-only network). Regardless, most service packages default to installing onto private agent nodes.


# Scale

DC/OS Vagrant allows for easy scaling up and down by adding and removing public or private agent nodes.

Note: DC/OS itself does not allow changing the number of master nodes after installation.

Adding more nodes to an existing cluster requires your VagrantConfig.yaml to have both new and old nodes configured.

## Add an Agent Node

Adding a node will not immediately change scheduled services by may allow pending tasks to be scheduled using the newly available resources.

```
# Example initial cluster deploy
vagrant up m1 a1 p1 boot
# Add a private agent node
vagrant up a2
# Add a public agent node
vagrant up p2
```

## Remove an Agent Node

Removing an agent node will cause all tasks running on that node to be rescheduled elsewhere, if resources allow.

```
# Example initial cluster deploy
vagrant up m1 a1 p1 boot
# Remove a private agent node
vagrant destroy -f a1
# Remove a public agent node
vagrant destroy -f p1
```

# Shutting Down and Deleting Your Cluster

The normal Vagrant way to shut down VMs is `vagrant halt`, but if you use that method then the cluster won't come up again. For similar reasons, `vagrant reload` and `vagrant suspend && vagrant resume` also may not work. For more information, see [JIRA VAGRANT-7](https://dcosjira.atlassian.net/browse/VAGRANT-7).

Instead, the recommended way to shut down a cluster is to destroy it (removing the the VMs and deleting their disks):

```
vagrant destroy -f
```
