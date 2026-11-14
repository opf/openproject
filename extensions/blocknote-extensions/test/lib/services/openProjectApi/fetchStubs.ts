export function mockResponse(props:Partial<Response>):Response {
  return props as Response;
}

export function calledUrl(calls:unknown[][], index = 0):string {
  return calls[index][0] as string;
}
