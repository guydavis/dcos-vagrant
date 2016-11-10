# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/vagrant-dcos'
require 'vagrant/util/downloader'
require 'yaml'
require 'fileutils'

UI = Vagrant::UI::Colored.new

## User Config
##############################################

class UserConfig
  attr_accessor :box
  attr_accessor :box_url
  attr_accessor :box_version
  attr_accessor :machine_config_path
  attr_accessor :config_path
  attr_accessor :dcos_version
  attr_accessor :generate_config_path
  attr_accessor :install_method
  attr_accessor :vagrant_mount_method
  attr_accessor :java_enabled
  attr_accessor :private_registry

  def self.from_env
    c = new
    c.box                  = ENV.fetch(env_var('box'), 'mesosphere/dcos-centos-virtualbox')
    c.box_url              = ENV.fetch(env_var('box_url'), 'https://downloads.dcos.io/dcos-vagrant/metadata.json')
    c.box_version          = ENV.fetch(env_var('box_version'), '~> 0.8.0')
    c.machine_config_path  = ENV.fetch(env_var('machine_config_path'), 'VagrantConfig.yaml')
    c.config_path          = ENV.fetch(env_var('config_path'), '')
    c.dcos_version         = ENV.fetch(env_var('dcos_version'), '1.8.6')
    c.generate_config_path = ENV.fetch(env_var('generate_config_path'), '')
    c.install_method       = ENV.fetch(env_var('install_method'), 'ssh_pull')
    c.vagrant_mount_method = ENV.fetch(env_var('vagrant_mount_method'), 'virtualbox')
    c.java_enabled         = (ENV.fetch(env_var('java_enabled'), 'false') == 'true')
    c.private_registry     = (ENV.fetch(env_var('private_registry'), 'false') == 'true')
    c
  end

  # resolve relative paths to be relative to the vagrant mount (allow remote urls)
  def self.path_to_url(path)
    %r{^\w*:\/\/} =~ path ? path : 'file:///vagrant/' + path
  end

  # convert field symbol to env var
  def self.env_var(field)
    "DCOS_#{field.to_s.upcase}"
  end

  # validate required fields and files
  def validate
    errors = []

    # Validate required fields
    required_fields = [
      :box,
      :box_url,
      :box_version,
      :machine_config_path,
      :install_method,
      :vagrant_mount_method
    ]
    required_fields.each do |field_name|
      field_value = send(field_name.to_sym)
      if field_value.nil? || field_value.empty?
        errors << "Missing required attribute: #{field_name}"
      end
    end

    raise ValidationError, errors unless errors.empty?

    if @dcos_version.empty? && @generate_config_path.empty?
      errors << "Either version (#{UserConfig.env_var('dcos_version')}) or installer (#{UserConfig.env_var('generate_config_path')}) must be specified via environment variables."
    end

    if @config_path.empty? && !@generate_config_path.empty?
      errors << "Config path (#{UserConfig.env_var('config_path')}) must be specified when installer (#{UserConfig.env_var('generate_config_path')}) is specified."
    end

    # Validate required files
    required_files = []
    required_files << :machine_config_path if !@machine_config_path.empty?
    required_files << :config_path if !@config_path.empty?
    required_files << :generate_config_path if !@config_path.empty?

    required_files.each do |field_name|
      file_path = send(field_name.to_sym)
      unless File.file?(file_path)
        errors << "File not found: '#{file_path}'. Ensure that the file exists or reconfigure its location (export #{UserConfig.env_var(field_name)}=<value>)."
      end
    end

    raise ValidationError, errors unless errors.empty?
  end

  # create environment for provisioning scripts
  def provision_env(machine_type)
    env = {
      'DCOS_CONFIG_PATH' => UserConfig.path_to_url(@config_path),
      'DCOS_GENERATE_CONFIG_PATH' => UserConfig.path_to_url(@generate_config_path),
      'DCOS_JAVA_ENABLED' => @java_enabled ? 'true' : 'false',
      'DCOS_PRIVATE_REGISTRY' => @private_registry ? 'true' : 'false'
    }
    if machine_type['memory-reserved']
      env['DCOS_TASK_MEMORY'] = machine_type['memory'] - machine_type['memory-reserved']
    end
    env
  end
end

class ValidationError < StandardError
  def initialize(list=[], msg="Validation Error")
    @list = list
    super(msg)
  end

  def publish
    UI.error 'Errors:'
    @list.each do |error|
      UI.error "  #{error}"
    end
    exit 2
  end
end

## Plugin Validation
##############################################

def validate_plugins
  required_plugins = [
    'vagrant-hostmanager'
  ]
  missing_plugins = []

  required_plugins.each do |plugin|
    unless Vagrant.has_plugin?(plugin)
      missing_plugins << "The '#{plugin}' plugin is required. Install it with 'vagrant plugin install #{plugin}'"
    end
  end

  unless missing_plugins.empty?
    missing_plugins.each { |x| UI.error x }
    return false
  end

  true
end

def validate_machine_types(machine_types)
  boot_types = machine_types.select { |_, cfg| cfg['type'] == 'boot' }
  if boot_types.empty?
    raise ValidationError, ['Must have at least one machine of type boot']
  end

  master_types = machine_types.select { |_, cfg| cfg['type'] == 'master' }
  if master_types.empty?
    raise ValidationError, ['Must have at least one machine of type master']
  end

  agent_types = machine_types.select { |_, cfg| cfg['type'] == 'agent-private' || cfg['type'] == 'agent-public' }
  if agent_types.empty?
    raise ValidationError, ['Must have at least one machine of type agent-private or agent-public']
  end
end

# path to the provision shell scripts
def provision_script_path(type)
  "./provision/bin/#{type}.sh"
end

# download installer, if not already downloaded
def download_installer(version)
  dcos_versions_path = 'dcos-versions.yaml'
  dcos_versions = YAML.load_file(Pathname.new(dcos_versions_path).realpath)
  dcos_sha = dcos_versions['shas'][version]

  if dcos_sha.nil? || dcos_sha.empty?
    raise ValidationError, ["Version not found: '#{version}'. See '#{dcos_versions_path}' for known versions. Either version (#{UserConfig.env_var('dcos_version')}) or installer (#{UserConfig.env_var('generate_config_path')}) must be specified via environment variables."]
  end

  url = "https://downloads.dcos.io/dcos/stable/commit/#{dcos_sha}/dcos_generate_config.sh"
  path = "installers/dcos/dcos_generate_config-#{version}.sh"

  FileUtils.mkdir_p Pathname.new(path).dirname

  return path if File.file?(path)

  UI.success "Downloading DC/OS #{version} Installer...", bold:true
  UI.info "Source: #{url}"
  UI.info "Destination: #{path}"
  dl = Vagrant::Util::Downloader.new(url, path, ui: UI)
  dl.download!

  path
end

def config_path(version)
  file_path = "etc/config-#{version}.yaml"
  return file_path if File.file?(file_path)

  if result = version.match(/^([^.]*\.[^.]*)\./)
    file_path = "etc/config-#{result[1]}.yaml"
    return file_path if File.file?(file_path)
  end

  raise ValidationError, ["No installer config found for version '#{version}' at 'etc/config-#{version}.yaml'. Ensure that the file exists or reconfigure its location (export #{UserConfig.env_var('config_path')}=<value>)."]
end

## One Time Setup
##############################################

if Vagrant::VERSION == '1.8.5'
  UI.error 'Unsupported Vagrant Version: 1.8.5', bold:true
  UI.error 'For more info, visit https://github.com/dcos/dcos-vagrant/blob/master/docs/troubleshooting.md#ssh-authentication-failure'
  UI.error ''
end

Vagrant.require_version '>= 1.8.4', '!= 1.8.5'

if Vagrant::VERSION == '1.8.6'
  # Monkey patch for network interface detection bug in Vagrant 1.8.6
  # https://github.com/mitchellh/vagrant/issues/7876
  require_relative 'lib/linux_network_interfaces'
end

begin

  UI.info 'Validating Plugins...'
  validate_plugins || exit(1)

  UI.info 'Validating User Config...'
  user_config = UserConfig.from_env
  user_config.validate

  # update installer based on version, unless specified
  if !user_config.dcos_version.empty? && user_config.generate_config_path.empty?
    user_config.generate_config_path = download_installer(user_config.dcos_version)
  end
  UI.success "Using DC/OS Installer: #{user_config.generate_config_path}", bold: true

  # update config based on version, unless specified
  if !user_config.dcos_version.empty? && user_config.config_path.empty?
    user_config.config_path = config_path(user_config.dcos_version)
  end
  UI.success "Using DC/OS Config: #{user_config.config_path}", bold: true

  UI.info 'Validating Machine Config...'
  machine_types = YAML.load_file(Pathname.new(user_config.machine_config_path).realpath)
  validate_machine_types(machine_types)

rescue ValidationError => e
  e.publish
end

UI.info 'Configuring VirtualBox Host-Only Network...'
# configure vbox host-only network
system(provision_script_path('vbox-network'))


## VM Creation & Provisioning
##############################################

Vagrant.configure(2) do |config|

  # configure vagrant-proxyconf plugin
  if Vagrant.has_plugin?("vagrant-proxyconf") and ENV['http_proxy']
    config.proxy.http     = ENV['http_proxy']
    config.proxy.https    = ENV['https_proxy']
    config.proxy.no_proxy = ENV['no_proxy']
  end

  # configure vagrant-hostmanager plugin
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  # Avoid random ssh key for demo purposes
  config.ssh.insert_key = false
  
  # Vagrant Plugin Configuration: vagrant-vbguest
  if Vagrant.has_plugin?('vagrant-vbguest')
    # enable auto update guest additions
    config.vbguest.auto_update = true
  end

  # Cache Yum updates across boxes
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.enable :yum
  end

  machine_types.each do |name, machine_type|
    config.vm.define name do |machine|
      machine.vm.hostname = "#{name}.dcos"

      # custom hostname aliases
      if machine_type['aliases']
        machine.hostmanager.aliases = machine_type['aliases'].join(' ').to_s
      end

      # custom mount type
      machine.vm.synced_folder '.', '/vagrant', type: user_config.vagrant_mount_method

      # allow explicit nil values in the machine_type to override the defaults
      machine.vm.box = machine_type.fetch('box', user_config.box)
      machine.vm.box_url = machine_type.fetch('box-url', user_config.box_url)
      machine.vm.box_version = machine_type.fetch('box-version', user_config.box_version)

      machine.vm.provider 'virtualbox' do |v, override|
        v.name = machine.vm.hostname
        v.cpus = machine_type['cpus'] || 2
        v.memory = machine_type['memory'] || 2048
        v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']

        override.vm.network :private_network, ip: machine_type['ip']
      end

      # Hack to remove loopback host alias that conflicts with vagrant-hostmanager
      # https://dcosjira.atlassian.net/browse/VAGRANT-15
      machine.vm.provision :shell, inline: "sed -i'' '/^127.0.0.1\\t#{machine.vm.hostname}\\t#{name}$/d' /etc/hosts"

      # provision a shared SSH key (required by DC/OS SSH installer)
      machine.vm.provision :dcos_ssh, name: 'Shared SSH Key'

      machine.vm.provision :shell do |vm|
        vm.name = 'Certificate Authorities'
        vm.path = provision_script_path('ca-certificates')
      end

      machine.vm.provision :shell do |vm|
	    vm.name = 'Install Probe'
        vm.path = provision_script_path('install-probe')
      end

      machine.vm.provision :shell do |vm|
        vm.name = 'Install jq'
        vm.path = provision_script_path('install-jq')
      end

      machine.vm.provision :shell do |vm|
        vm.name = 'Install DC/OS Postflight'
        vm.path = provision_script_path('install-postflight')
      end

      case machine_type['type']
      when 'agent-private', 'agent-public'
        machine.vm.provision :shell do |vm|
          vm.name = 'Install Mesos Memory Modifier'
          vm.path = provision_script_path('install-mesos-memory')
        end
      end

      # Update packages in the dcos-centos-virtualbox image
      machine.vm.provision :shell, inline: "echo 'Updating CentOS with yum....' && yum update -q -y || echo 'System update with yum failed. Please check your proxy setting and update manually later.'"

      if ENV['http_proxy']
        machine.vm.provision :shell do |vm|
          vm.name = 'Docker Proxy Config'
          vm.path = provision_script_path('docker-proxy')
          vm.args = [ ENV['http_proxy'], ENV['https_proxy'], ENV['no_proxy'] ]
        end
      end

      if user_config.private_registry
        machine.vm.provision :shell do |vm|
          vm.name = 'Start Private Docker Registry'
          vm.path = provision_script_path('insecure-registry')
        end
      end

      script_path = provision_script_path("type-#{machine_type['type']}")
      if File.exist?(script_path)
        machine.vm.provision :shell do |vm|
          vm.name = "DC/OS #{machine_type['type'].capitalize}"
          vm.path = script_path
          vm.env = user_config.provision_env(machine_type)
        end
      end

      if machine_type['type'] == 'boot'
        # install DC/OS after boot machine is provisioned
        machine.vm.provision :dcos_install do |dcos|
          dcos.install_method = user_config.install_method
          dcos.machine_types = machine_types
          dcos.config_template_path = user_config.config_path
        end
      end
    end
  end
end
