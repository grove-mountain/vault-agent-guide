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
  <p>Finance AP-App secrets:</p>
  {{- with secret "secret/finance/ap-app/config" }}
  <ul>
  <li><pre>username: {{ .Data.username }}</pre></li>
  <li><pre>password: {{ .Data.password }}</pre></li>
  </ul>
  {{ end }}
  <p>IT Operations secrets:</p>
  {{- with secret "secret/it/operations/config" }}
  <ul>
  <li><pre>username: {{ .Data.username }}</pre></li>
  <li><pre>password: {{ .Data.password }}</pre></li>
  </ul>
  {{ end }}
  <p>IT Support secrets:</p>
  {{- with secret "secret/it/support/config" }}
  <ul>
  <li><pre>username: {{ .Data.username }}</pre></li>
  <li><pre>password: {{ .Data.password }}</pre></li>
  </ul>
  {{ end }}
  </body>
  </html>  
  EOH
}
