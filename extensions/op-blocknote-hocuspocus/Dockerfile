FROM node:24.18.0
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src/ /app/src
EXPOSE 1234

# Start the app
CMD ["npm", "start", "--", "--no-daemon"]
