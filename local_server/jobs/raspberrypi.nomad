# nomad job run -address=http://192.168.0.24:4646 raspberrypi.nomad
# nomad status -address=http://192.168.0.24:4646 raspberrypi
# http://haproxy.service.consul:1936/
# http://haproxy.service.consul:8080/
job "raspberrypi" {
	datacenters = ["private"]
	region = "local"
	type = "service"

	group "haproxy" {
		count = 1

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
  nameserver consul 192.168.0.47:8600
  accepted_payload_size 8192
  hold valid 5s
EOF

				destination = "local/haproxy.cfg"
			}

			resources {
				cpu = 200
				memory = 128
				network {
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
				memory = 128
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
