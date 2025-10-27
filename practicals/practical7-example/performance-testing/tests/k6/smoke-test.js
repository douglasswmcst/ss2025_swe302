import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 1,
  duration: '30s',
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  // Quick checks that everything works
  const endpoints = [
    { name: 'Homepage', url: BASE_URL },
    { name: 'Random Dog API', url: `${BASE_URL}/api/dogs` },
    { name: 'Breeds API', url: `${BASE_URL}/api/dogs/breeds` },
  ];

  endpoints.forEach((endpoint) => {
    const response = http.get(endpoint.url);
    check(response, {
      [`${endpoint.name} - status is 200`]: (r) => r.status === 200,
      [`${endpoint.name} - response time < 1s`]: (r) => r.timings.duration < 1000,
    });
  });
}
