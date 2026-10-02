import { http, HttpResponse } from 'msw';
import { worker } from '../mocks/browser';
import { requestedWorkPackageIds, workPackageCollection, workPackageFor } from '../mocks/handlers';

const WORK_PACKAGES_ENDPOINT = 'http://localhost:3000/api/v3/work_packages';

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

/** Leaves the given work packages out of every batch load, as the API does for invisible ones. */
export function hideWorkPackages(...hidden:number[]):void {
  worker.use(
    http.get(WORK_PACKAGES_ENDPOINT, ({ request }) => {
      const ids = requestedWorkPackageIds(request);
      if (!ids) return undefined;

      return workPackageCollection(ids.filter((id) => !hidden.includes(Number(id))).map(workPackageFor));
    })
  );
}

/** Makes the given work packages crash the server, both alone and in any batch load holding them. */
export function breakWorkPackages(...broken:number[]):void {
  const serverError = () => HttpResponse.json({ message: 'Internal Server Error' }, { status: 500 });

  worker.use(
    http.get(WORK_PACKAGES_ENDPOINT, ({ request }) => {
      const ids = requestedWorkPackageIds(request);
      return ids?.some((id) => broken.includes(Number(id))) ? serverError() : undefined;
    }),
    http.get(`${WORK_PACKAGES_ENDPOINT}/:id`, ({ params }) =>
      (broken.includes(Number(params.id)) ? serverError() : undefined))
  );
}
