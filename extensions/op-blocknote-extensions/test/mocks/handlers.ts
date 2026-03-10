import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/wp/:id', (req) => {
    return HttpResponse.json({
      id: 123,
      subject: "Test WP",
      _links: {
        self: { href: "/wp/123" },
        type: { title: "Feature", href: "/types/1" },
        status: { title: "Open", href: "/statuses/1" },
        assignee: { title: "John Doe", href: "/users/1" },
      },
    });
  }),
];