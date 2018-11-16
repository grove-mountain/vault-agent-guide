storage "inmem" {}

listener "tcp" {
  address = "10.252.38.69:8200"
  tls_disable = "true"
}
ui=true
