#
# Cookbook Name:: wal-e
# Recipe:: default

# run apt-get update on debian based systems before trying to install python-dev
# see: https://tickets.opscode.com/browse/COOK-3240
if platform_family?('debian')
  include_recipe 'apt'
end

#install packages
node[:wal_e][:packages].each do |pkg|
  package pkg
end

#install python modules with pip unless overriden
unless node[:wal_e][:pips].nil?
  include_recipe "python::pip"
  node[:wal_e][:pips].each do |pp|
    python_pip "gevent"
  end
end

code_path = "#{Chef::Config[:file_cache_path]}/wal-e"

bash "install_wal_e" do
  cwd code_path
  code <<-EOH
    /usr/bin/python ./setup.py install
  EOH
  action :nothing
end

git code_path do
  repository "https://github.com/wal-e/wal-e.git"
  revision node[:wal_e][:git_version]
  notifies :run, "bash[install_wal_e]"
end

directory node[:wal_e][:env_dir] do
  user    node[:wal_e][:user]
  group   node[:wal_e][:group]
  mode    "0550"
end

vars = {'WALE_WABS_PREFIX'      => node[:wal_e][:wabs_prefix],
        'WALE_S3_PREFIX'        => node[:wal_e][:s3_prefix]}

if node[:wal_e][:use_encrypted_bag].nil? or node[:wal_e][:encrypted_bag].nil?
  vars['AWS_ACCESS_KEY_ID']     = node[:wal_e][:aws_access_key]
  vars['AWS_SECRET_ACCESS_KEY'] = node[:wal_e][:aws_secret_key]
  vars['WABS_ACCOUNT_NAME']     = node[:wal_e][:wabs_account_name]
  vars['WABS_ACCESS_KEY']       = node[:wal_e][:wabs_access_key]
else
  Chef::Log.info("Using encrypted data bag '#{node[:wal_e][:encrypted_bag]}' for WAL-E related access keys.")
  wal_e_secrets = Chef::EncryptedDataBagItem.load(node[:wal_e][:encrypted_bag], "wal_e")

  %w{ AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY WABS_ACCOUNT_NAME WABS_ACCESS_KEY }.each do |attr|
    vars[attr] = wal_e_secrets[attr]
  end
end

vars.each do |key, value|
  unless value.nil?
    file "#{node[:wal_e][:env_dir]}/#{key}" do
      content value
      user    node[:wal_e][:user]
      group   node[:wal_e][:group]
      mode    "0440"
    end
  end
end

cron "wal_e_base_backup" do
  user node[:wal_e][:user]
  command "/usr/bin/envdir #{node[:wal_e][:env_dir]} /usr/local/bin/wal-e backup-push #{node[:wal_e][:pgdata_dir]}"

  minute node[:wal_e][:base_backup][:minute]
  hour node[:wal_e][:base_backup][:hour]
  day node[:wal_e][:base_backup][:day]
  month node[:wal_e][:base_backup][:month]
  weekday node[:wal_e][:base_backup][:weekday]
end
