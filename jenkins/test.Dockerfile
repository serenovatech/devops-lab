# Holds the Poultry source and its development tools, so Jenkins can run the same checks as CI.
# Not the slim image: it lacks the build tools for the optional better-sqlite3 package the tests use.
FROM node:22-bookworm
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
