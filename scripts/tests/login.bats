#!/usr/bin/env bats

@test "ssh_uname" {
  result=$(ssh -l root -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR 192.168.7.2 "uname -a")
  check_uname=$(echo $result | grep GNU/Linux | wc -l)

  [ "$check_uname" -eq 1 ]
}

