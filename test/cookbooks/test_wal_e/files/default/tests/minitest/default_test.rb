require 'minitest-chef-handler'
include MiniTest::Chef::Resources
include MiniTest::Chef::Assertions

class TestEnvDirExists < MiniTest::Chef::TestCase

  def test_env_dir_exist
    assert File.directory?('/etc/wal-e')
  end

  def test_wabs_account_exist
    assert_file '/etc/wal-e/WABS_ACCOUNT_NAME', "root", "root", "0440"
    assert IO.read('/etc/wal-e/WABS_ACCOUNT_NAME') == 'test-wabs_account_name', "WABS account not written to env dir"
  end

  def test_wabs_secret_exist
    assert_file '/etc/wal-e/WABS_ACCESS_KEY', "root", "root", "0440"
    assert IO.read('/etc/wal-e/WABS_ACCESS_KEY') == 'test-wabs_access_key', "WABS secret not written to env dir"
  end

  def test_aws_access_key_not_exist
    assert !File.exist?('/etc/wal-e/AWS_ACCESS_KEY_ID')
  end

  def test_aws_access_secret_not_exist
    assert !File.exist?('/etc/wal-e/AWS_SECRET_ACCESS_KEY')
  end

  def test_crontab_entry_created
    assert_cron_exists cron("wal_e_base_backup")
  end

end
