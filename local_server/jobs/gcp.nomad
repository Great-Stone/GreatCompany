# nomad job run -address=http://192.168.0.24:4646 gcp.nomad
# nomad server join :4648
# nomad job run -address=http://192.168.0.24:4646 gcp.nomad
# nomad status -address=http://192.168.0.24:4646 gcp
# http://haproxy.service.asia-northeast1.consul:1936/
# http://haproxy.service.asia-northeast1.consul:8080/
job "gcp" {
	datacenters = ["asia-northeast1"]
	region = "gcp"
	type = "service"

	group "haproxy" {
		count = 1

		constraint {
			attribute    = "${meta.selector}"
			set_contains = "haproxy"
		}

		task "haproxy" {
			driver = "docker"

			config {
				image = "haproxy:latest"
				hostname = "docker.io"
				network_mode = "host"				
				volumes = [
					"local/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg",
				]
			}

			template {
				data = <<EOF
defaults
   mode http

frontend stats
   bind *:1936
   stats uri /
   stats show-legends
   no log

frontend http_front
   bind *:8080
   default_backend http_back

backend http_back
    balance roundrobin
    server-template mywebapp 10 _nginx-webserver._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check

resolvers consul
  nameserver consul 127.0.0.1:8600
  accepted_payload_size 8192
  hold valid 5s
EOF

				destination = "local/haproxy.cfg"
			}

			resources {
				cpu = 300
				memory = 128
				network {
					mode = "bridge"
					mbits = 10
					port "http" {
						static = 8080
					}
					port "haproxy_ui" {
						static = 1936
					}
				}
			}

			service {
				name = "haproxy"
				check {
					name = "alive"
					type = "tcp"
          			port = "http"
					interval = "10s"
					timeout = "2s"
				}
			}
		}
	}

	group "webserver" {
		count = 3

		constraint {
			attribute    = "${meta.selector}"
			set_contains = "nginx"
		}

		# Define a task to run
		task "nginx-webserver" {
			env {
				PORT    = "${NOMAD_PORT_http}"
				NODE_IP = "${NOMAD_IP_http}"
			}
			
			driver = "docker"

			config {
				image = "nginx:latest"
				hostname = "docker.io"
				network_mode = "bridge"
        		port_map {
					app = 80
				}
			}

			resources {
				cpu = 200
				memory = 96
				network {
					mbits = 10
					port "app" {}
				}
			}

			service {
				name = "nginx-webserver"
				port = "app"
				check {
					name = "alive"
					type = "http"
          			path = "/"
					interval = "10s"
					timeout = "2s"
				}
			}
		}
	}
}
