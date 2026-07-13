import { Logger } from "@hocuspocus/extension-logger";
import { Server } from "@hocuspocus/server";
import { OpenProjectApi } from "./extensions/openProjectApi";

const server = new Server({
  port: 1234,
  quiet: false,
  extensions: [
    new OpenProjectApi(),
    new Logger({
      onChange: false,
    }),
  ],
});

server.listen();

