import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

const totalRequests = new Counter('total_requests');

export const options = {
  scenarios: {
    light_load: {
      executor: 'constant-vus',
      vus: 10,
      duration: '1m',
    },
    spike_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 50 },  // Spike to 50 users
        { duration: '30s', target: 50 },  // Stay at 50
        { duration: '10s', target: 0 },   // Drop back
      ],
      startTime: '1m',
    },
  },
  thresholds: {
    http_req_duration: ['p(90)<1000'], // 90% under 1s
    http_req_failed: ['rate<0.05'],     // Less than 5% errors
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  // Simulate real user flow

  // 1. Load homepage
  let response = http.get(BASE_URL);
  check(response, { 'homepage loaded': (r) => r.status === 200 });
  totalRequests.add(1);
  sleep(2);

  // 2. Fetch breeds
  response = http.get(`${BASE_URL}/api/dogs/breeds`);
  check(response, { 'breeds loaded': (r) => r.status === 200 });
  totalRequests.add(1);
  sleep(1);

  // 3. Get random dog (simulating button click)
  response = http.get(`${BASE_URL}/api/dogs`);
  check(response, { 'random dog loaded': (r) => r.status === 200 });
  totalRequests.add(1);
  sleep(3);

  // 4. Get specific breed (simulating breed selection)
  const breeds = ['husky', 'corgi', 'retriever', 'bulldog', 'poodle'];
  const randomBreed = breeds[Math.floor(Math.random() * breeds.length)];
  response = http.get(`${BASE_URL}/api/dogs?breed=${randomBreed}`);
  check(response, { 'specific breed loaded': (r) => r.status === 200 });
  totalRequests.add(1);
  sleep(2);
}
