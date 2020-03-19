job "example" {
  datacenters = ["private"]
  region = "local"
  type = "service"

	# Configure the job to do rolling updates
	update {
		# Stagger updates every 10 seconds
		stagger = "10s"

		# Update a single task at a time
		max_parallel = 1
	}

	group "webserver" {
		count = 1

		restart {
			interval = "1m"
			attempts = 2
			delay = "30s"
			mode = "delay"
		}

		# Define a task to run
		task "nginx" {
			# Use Docker to run the task.
			driver = "docker"

			config {
				image = "nginx:latest"
				hostname = "docker.io"
				network_mode = "host"
				// command = "uwsgi"
				// args = [
				// 	"--env ENV=dev",
				// 	"--die-on-term",
				// 	"--master",
				// 	"--http ${NOMAD_PORT_http}",
				// 	"--workers 1", "--threads 1",
				// 	"--need-app", "--callable app",
				// 	"--chdir /app",
 				// 	"--file app.py"
				// ]
			}

			resources {
				cpu = 1500
				memory = 512
				network {
					mbits = 10
					port "http" {}
				}
			}

			service {
				port = "http"
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