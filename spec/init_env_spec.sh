#shellcheck shell=sh
# shellspec是一个BDD风格的shell脚本测试框架
# 使用类似于RSpec的语法来描述测试用例

# 描述被测试的脚本文件
Describe 'init_env.sh'
  # 包含要测试的脚本文件
  Include init_env.sh

  # 测试环境变量加载功能
  Describe 'load_env'
    # 测试用例：加载.env文件
    It 'loads environment variables from .env file'
      # 执行load_env函数
      When call load_env
      # 验证函数执行成功
      The status should be success
    End
  End

  # 测试用户创建功能
  Describe 'setup_user'
    # 测试用例：创建新用户
    It 'creates a new user'
      # 调用setup_user函数，传入测试用户名和密码
      When call setup_user "testuser" "testpass"
      # 验证函数执行成功
      The status should be success
    End
  End

  # 测试SSH配置功能
  Describe 'setup_ssh'
    # 测试用例：配置SSH
    It 'sets up SSH configuration'
      # 设置测试用的SSH公钥
      export SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtest test@test"
      # 调用setup_ssh函数
      When call setup_ssh "testuser"
      # 验证函数执行成功
      The status should be success
    End
  End

  # 测试pip配置功能
  Describe 'setup_pip'
    # 测试用例：配置pip使用清华镜像
    It 'configures pip with Tsinghua mirror'
      # 调用setup_pip函数
      When call setup_pip "testuser"
      # 验证函数执行成功
      The status should be success
      # 验证配置文件是否存在
      The path "/home/testuser/.pip/pip.conf" should be exist
    End
  End

  # 测试fish shell配置功能
  Describe 'setup_fish'
    # 测试用例：安装和配置fish shell
    It 'installs and configures fish shell'
      # 调用setup_fish函数
      When call setup_fish "testuser"
      # 验证函数执行成功
      The status should be success
      # 验证配置文件是否存在
      The path "/home/testuser/.config/fish/config.fish" should be exist
    End
  End
End 