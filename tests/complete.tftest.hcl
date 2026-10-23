# Run only by the nightly integration workflow, against real cloud credentials.
variables {
  project_id          = "olensys-integration"
  network_name        = "integration-net"
  subnet_name         = "integration-subnet"
  pods_range_name     = "pods"
  services_range_name = "services"
}

run "apply_minimal" {
  command = apply

  module {
    source = "./examples/minimal"
  }
}
