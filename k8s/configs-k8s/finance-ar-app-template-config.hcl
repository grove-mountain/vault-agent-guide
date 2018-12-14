vault {
  renew_token = false
  retry {
    backoff = "1s"
  }
}

template {
  destination = "/etc/secrets/index.html"
  contents = <<EOH
  <html>
  <body>
  <p>Finance AR-App secrets:</p>
  {{- with secret "secret/finance/ar-app/config" }}
  <ul>
  <li><pre>username: {{ .Data.username }}</pre></li>
  <li><pre>password: {{ .Data.password }}</pre></li>
  </ul>
  {{ end }}
  </body>
  </html>  
  EOH
}
