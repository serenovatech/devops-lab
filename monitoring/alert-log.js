// Stands in for Slack or Teams: prints each alert Alertmanager sends. See it with:
//   docker compose logs -f alert-log
const http = require('node:http')

http
  .createServer((req, res) => {
    let raw = ''
    req.on('data', (chunk) => (raw += chunk))
    req.on('end', () => {
      try {
        for (const alert of JSON.parse(raw).alerts ?? []) {
          console.log(`${alert.status.toUpperCase()} ${alert.labels.alertname}: ${alert.annotations.summary}`)
        }
      } catch {
        console.log(`Could not read this message: ${raw}`)
      }
      res.end()
    })
  })
  .listen(5001, () => console.log('Waiting for alerts on port 5001'))
