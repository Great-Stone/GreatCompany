resource "null_resource" "isntall_consul_by_choco" {
  provisioner "local-exec" {
    command = "choco install -y consul"
  }
  provisioner "local-exec" {
    command = "sc.exe create Consul binPath= \"C:\\ProgramData\\chocolatey\\lib\\consul\\tools\\consul.exe agent -http-addr=0.0.0.0 -bind=0.0.0.0 -config-dir=C:\\ProgramData\\consul\\config\" start= auto"
  }

  triggers = {
    always_run = timestamp()
  }
}