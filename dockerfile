# --- Stage 1: Builder ---
# Use a Node.js image as the base for building
FROM node:lts as builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock) first
# This allows Docker to cache dependencies if these files don't change
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Build the Next.js application
# The output (.next folder) will be used in the next stage
RUN npm run build

# --- Stage 2: Runner ---
# Use a smaller, production-ready Node.js image
FROM node:lts-slim

# Set the working directory
WORKDIR /app

# Copy only necessary files from the builder stage
# Copy the built application (.next folder)
COPY --from=builder /app/.next ./.next

# Copy public assets
COPY --from=builder /app/public ./public

# Copy package.json (needed for 'npm start')
COPY --from=builder /app/package.json ./package.json

# Install *only* production dependencies
# This is important for a small and secure runtime image
RUN npm install --only=production

# Expose the port Next.js runs on (default is 3000)
EXPOSE 3000

# Command to run the application in production mode
CMD ["npm", "start"]

# Optional: Add health check (useful for orchestration)
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD curl -f http://localhost:3000 || exit 1
