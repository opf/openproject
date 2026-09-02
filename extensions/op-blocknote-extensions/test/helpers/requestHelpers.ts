import { worker } from '../mocks/browser';

export async function requestsDuring(endpoint:string, act:() => Promise<void>):Promise<string[]> {
  const asked:string[] = [];
  const record = ({ request }:{ request:Request }) => {
    if (request.url.includes(endpoint)) asked.push(request.url);
  };

  worker.events.on('request:start', record);
  try {
    await act();
  } finally {
    worker.events.removeListener('request:start', record);
  }

  return asked;
}
