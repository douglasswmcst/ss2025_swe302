import http from "k6/http";
import { check } from "k6";

export const options = {
  vus: 500,
  duration: "30s",
  thresholds: {
    http_req_duration: ["avg<100", "p(95)<200"],
    "http_req_connecting{cdnAsset:true}": ["p(95)<100"],
  },
};

const BASE_URL = __ENV.BASE_URL || "https://504dbfd5b6f1.ngrok-free.app";

export default function () {
  // Quick checks that everything works
  const endpoints = [
    { name: "Homepage", url: BASE_URL },
    { name: "Random Dog API", url: `${BASE_URL}/api/dogs` },
    { name: "Breeds API", url: `${BASE_URL}/api/dogs/breeds` },
  ];

  endpoints.forEach((endpoint) => {
    const response = http.get(endpoint.url);
    check(response, {
      [`${endpoint.name} - status is 200`]: (r) => r.status === 200,
      [`${endpoint.name} - response time < 1s`]: (r) =>
        r.timings.duration < 1000,
    });
  });
}
