FROM node:22.22.3
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src/ /app/src
EXPOSE 1234

# Start the app
CMD ["npm", "start", "--", "--no-daemon"]
