
# Create GH token ( https://www.runatlantis.io/docs/access-credentials.html#github-user )

# Expose Atlantis server

# Run Atlantis Server ( Docker )
```bash
docker run --name atlantis-server -d -p 0.0.0.0:4141:4141 ghcr.io/runatlantis/atlantis:dev-debian-592c7c6 server --atlantis-url=http://<external_endpoint> --gh-user=luismiguelsaez --gh-token=<github_pat> --repo-allowlist="github.com/luismiguelsaez/*" --gh-webhook-secret=<github_webhook_secret>
```

# Configure GH webhook ( https://www.runatlantis.io/docs/configuring-webhooks.html#github-github-enterprise )
